package FusionInventory::Agent;

use strict;
use warnings;

use Cwd;
use English qw(-no_match_vars);
use UNIVERSAL::require;
use File::Glob;
use IO::Handle;
use POSIX ":sys_wait_h"; # WNOHANG
use Storable 'dclone';

use FusionInventory::Agent::Config;
use FusionInventory::Agent::HTTP::Client::OCS;
use FusionInventory::Agent::Logger;
use FusionInventory::Agent::Storage;
use FusionInventory::Agent::Target::Local;
use FusionInventory::Agent::Target::Server;
use FusionInventory::Agent::Tools;
use FusionInventory::Agent::Tools::Hostname;
use FusionInventory::Agent::XML::Query::Prolog;

our $VERSION = '2.3.18';
our $VERSION_STRING = _versionString($VERSION);
our $AGENT_STRING = "FusionInventory-Agent_v$VERSION";
our $CONTINUE_WORD = "...";

sub _versionString {
    my ($VERSION) = @_;

    my $string = "FusionInventory Agent ($VERSION)";
    if ($VERSION =~ /^\d\.\d\.99(\d\d)/) {
        $string .= " **THIS IS A DEVELOPMENT RELEASE **";
    }

    return $string;
}

sub new {
    my ($class, %params) = @_;

    my $self = {
        status  => 'unknown',
        confdir => $params{confdir},
        datadir => $params{datadir},
        libdir  => $params{libdir},
        vardir  => $params{vardir},
        tasks   => []
    };
    bless $self, $class;

    return $self;
}

sub init {
    my ($self, %params) = @_;

    my $config = FusionInventory::Agent::Config->new(
        confdir => $self->{confdir},
        options => $params{options},
    );
    $self->{config} = $config;

    my $verbosity = $config->{debug} && $config->{debug} == 1 ? LOG_DEBUG  :
                    $config->{debug} && $config->{debug} == 2 ? LOG_DEBUG2 :
                                                                LOG_INFO   ;

    my $logger = FusionInventory::Agent::Logger->new(
        config    => $config,
        backends  => $config->{logger},
        verbosity => $verbosity
    );
    $self->{logger} = $logger;

    $logger->debug("Configuration directory: $self->{confdir}");
    $logger->debug("Data directory: $self->{datadir}");
    $logger->debug("Storage directory: $self->{vardir}");
    $logger->debug("Lib directory: $self->{libdir}");

    $self->{storage} = FusionInventory::Agent::Storage->new(
        logger    => $logger,
        directory => $self->{vardir}
    );

    # handle persistent state
    $self->_loadState();

    $self->{deviceid} = _computeDeviceId() if !$self->{deviceid};

    $self->_saveState();

    # create target list
    if ($config->{local}) {
        foreach my $path (@{$config->{local}}) {
            push @{$self->{targets}},
                FusionInventory::Agent::Target::Local->new(
                    logger     => $logger,
                    deviceid   => $self->{deviceid},
                    delaytime  => $config->{delaytime},
                    basevardir => $self->{vardir},
                    path       => $path,
                    html       => $config->{html},
                );
        }
    }

    if ($config->{server}) {
        foreach my $url (@{$config->{server}}) {
            push @{$self->{targets}},
                FusionInventory::Agent::Target::Server->new(
                    logger     => $logger,
                    deviceid   => $self->{deviceid},
                    delaytime  => $config->{delaytime},
                    basevardir => $self->{vardir},
                    url        => $url,
                    tag        => $config->{tag},
                );
        }
    }

    if (!$self->{targets}) {
        $logger->error("No target defined, aborting");
        exit 1;
    }

    # compute list of allowed tasks
    my %available = $self->getAvailableTasks(disabledTasks => $config->{'no-task'});
    my @tasks = keys %available;
    my @plannedTasks = $self->computeTaskExecutionPlan(@tasks, $logger);
    $self->{tasksExecutionPlan} = \@plannedTasks;

    if (!@tasks) {
        $logger->error("No tasks available, aborting");
        exit 1;
    }

    $logger->debug("Available tasks:");
    foreach my $task (keys %available) {
        $logger->debug("- $task: $available{$task}");
    }
    $logger->debug("Planned tasks:");
    foreach my $task (@{$self->{tasksExecutionPlan}}) {
        $logger->debug("- $task: $available{$task}");
    }

    $self->{tasks} = \@tasks;

    if ($config->{daemon}) {
        my $pidfile  = $config->{pidfile} ||
                       $self->{vardir} . '/fusioninventory.pid';

        if ($self->_isAlreadyRunning($pidfile)) {
            $logger->error("An agent is already running, exiting...");
            exit 1;
        }
        if (!$config->{'no-fork'}) {

            Proc::Daemon->require();
            if ($EVAL_ERROR) {
                $logger->error("Failed to load Proc::Daemon: $EVAL_ERROR");
                exit 1;
            }

            # If we use relative path, we must stay in the current directory
            my $workdir = substr($self->{libdir}, 0, 1) eq '/' ? '/' : getcwd();

            Proc::Daemon::Init({
                work_dir => $workdir,
                pid_file => $pidfile
            });

            $self->{logger}->debug("Agent daemonized");
        }
    }

    # create HTTP interface
    if (($config->{daemon} || $config->{service}) && !$config->{'no-httpd'}) {
        FusionInventory::Agent::HTTP::Server->require();
        if ($EVAL_ERROR) {
            $logger->error("Failed to load HTTP server: $EVAL_ERROR");
        } else {
            $self->{server} = FusionInventory::Agent::HTTP::Server->new(
                logger          => $logger,
                agent           => $self,
                htmldir         => $self->{datadir} . '/html',
                ip              => $config->{'httpd-ip'},
                port            => $config->{'httpd-port'},
                trust           => $config->{'httpd-trust'}
            );
            $self->{server}->init()
                or delete $self->{server};
        }
    }

    # install signal handler to handle graceful exit
    $SIG{INT}     = sub { $self->terminate(); exit 0; };
    $SIG{TERM}    = sub { $self->terminate(); exit 0; };

    $self->{logger}->info("FusionInventory Agent starting")
        if $self->{config}->{daemon} || $self->{config}->{service};

    $self->{logger}->info("Options 'no-task' and 'tasks' are both used. Be careful that 'no-task' always excludes tasks.")
        if ($self->{config}->isParamArrayAndFilled('no-task') && $self->{config}->isParamArrayAndFilled('tasks'));
}

sub run {
    my ($self) = @_;

    $self->{status} = 'waiting';

    if ($self->{config}->{daemon} || $self->{config}->{service}) {

        # background mode:
        while (1) {
            my $time = time();
            foreach my $target (@{$self->{targets}}) {
                next if $time < $target->getNextRunDate();

                eval {
                    $self->_runTarget($target);
                };
                $self->{logger}->error($EVAL_ERROR) if $EVAL_ERROR;
                $target->resetNextRunDate();
            }

            if ($self->{server}) {
                # check for http interface messages
                $self->{server}->handleRequests() ;
            } else {
                delay(1);
            }
        }
    } else {
        # foreground mode: check each targets once
        my $time = time();
        foreach my $target (@{$self->{targets}}) {
            if ($self->{config}->{lazy} && $time < $target->getNextRunDate()) {
                $self->{logger}->info(
                    "$target->{id} is not ready yet, next server contact " .
                    "planned for " . localtime($target->getNextRunDate())
                );
                next;
            }

            eval {
                $self->_runTarget($target);
            };
            $self->{logger}->error($EVAL_ERROR) if $EVAL_ERROR;
        }
    }
}

sub terminate {
    my ($self) = @_;

    $self->{logger}->info("FusionInventory Agent exiting")
        if $self->{config}->{daemon} || $self->{config}->{service};
    $self->{current_task}->abort() if $self->{current_task};
}

sub _runTarget {
    my ($self, $target) = @_;

    # the prolog dialog must be done once for all tasks,
    # but only for server targets
    my $response;
    if ($target->isa('FusionInventory::Agent::Target::Server')) {
        my $client = FusionInventory::Agent::HTTP::Client::OCS->new(
            logger       => $self->{logger},
            timeout      => $self->{timeout},
            user         => $self->{config}->{user},
            password     => $self->{config}->{password},
            proxy        => $self->{config}->{proxy},
            ca_cert_file => $self->{config}->{'ca-cert-file'},
            ca_cert_dir  => $self->{config}->{'ca-cert-dir'},
            no_ssl_check => $self->{config}->{'no-ssl-check'},
        );

        my $prolog = FusionInventory::Agent::XML::Query::Prolog->new(
            deviceid => $self->{deviceid},
        );

        $self->{logger}->info("sending prolog request to server $target->{id}");
        $response = $client->send(
            url     => $target->getUrl(),
            message => $prolog
        );
        die "No answer from the server" unless $response;

        # update target
        my $content = $response->getContent();
        if (defined($content->{PROLOG_FREQ})) {
            $target->setMaxDelay($content->{PROLOG_FREQ} * 3600);
        }
    }

    foreach my $name (@{$self->{tasksExecutionPlan}}) {
        eval {
            $self->_runTask($target, $name, $response);
        };
        $self->{logger}->error($EVAL_ERROR) if $EVAL_ERROR;
        $self->{status} = 'waiting';
    }
}

sub _runTask {
    my ($self, $target, $name, $response) = @_;

    $self->{status} = "running task $name";

    if ($self->{config}->{daemon} || $self->{config}->{service}) {
        # server mode: run each task in a child process
        if (my $pid = fork()) {
            # parent
            while (waitpid($pid, WNOHANG) == 0) {
                if ($self->{server}) {
                    $self->{server}->handleRequests() ;
                } else {
                    delay(1);
                }
            }
        } else {
            # child
            die "fork failed: $ERRNO" unless defined $pid;

            $self->{logger}->debug("forking process $PID to handle task $name");
            $self->_runTaskReal($target, $name, $response);
            exit(0);
        }
    } else {
        # standalone mode: run each task directly
        $self->_runTaskReal($target, $name, $response);
    }
}

sub _runTaskReal {
    my ($self, $target, $name, $response) = @_;

    my $class = "FusionInventory::Agent::Task::$name";

    $class->require();

    my $task = $class->new(
        config       => $self->{config},
        confdir      => $self->{confdir},
        datadir      => $self->{datadir},
        logger       => $self->{logger},
        target       => $target,
        deviceid     => $self->{deviceid},
    );

    return if !$task->isEnabled($response);

    $self->{logger}->info("running task $name");
    $self->{current_task} = $task;

    $task->run(
        user         => $self->{config}->{user},
        password     => $self->{config}->{password},
        proxy        => $self->{config}->{proxy},
        ca_cert_file => $self->{config}->{'ca-cert-file'},
        ca_cert_dir  => $self->{config}->{'ca-cert-dir'},
        no_ssl_check => $self->{config}->{'no-ssl-check'},
    );
    delete $self->{current_task};
}

sub getStatus {
    my ($self) = @_;
    return $self->{status};
}

sub getTargets {
    my ($self) = @_;

    return @{$self->{targets}};
}

sub getAvailableTasks {
    my ($self, %params) = @_;

    my %tasks;
    my %disabled  = map { lc($_) => 1 } @{$params{disabledTasks}};

    # tasks may be located only in agent libdir
    my $directory = $self->{libdir};
    $directory =~ s,\\,/,g;
    my $subdirectory = "FusionInventory/Agent/Task";
    # look for all perl modules here
    foreach my $file (File::Glob::glob("$directory/$subdirectory/*.pm")) {
        next unless $file =~ m{($subdirectory/(\S+)\.pm)$};
        my $module = file2module($1);
        my $name = file2module($2);

        next if $disabled{lc($name)};

        my $version;
        if ($self->{config}->{daemon} || $self->{config}->{service}) {
            # server mode: check each task version in a child process
            my ($reader, $writer);
            pipe($reader, $writer);
            $writer->autoflush(1);

            if (my $pid = fork()) {
                # parent
                close $writer;
                $version = <$reader>;
                close $reader;
                waitpid($pid, 0);
            } else {
                # child
                die "fork failed: $ERRNO" unless defined $pid;

                close $reader;
                $version = $self->_getTaskVersion($module);
                print $writer $version if $version;
                close $writer;
                exit(0);
            }
        } else {
            # standalone mode: check each task version directly
            $version = $self->_getTaskVersion($module);
        }

        # no version means non-functionning task
        next unless $version;

        $tasks{$name} = $version;
    }

    return %tasks;
}

sub _getTaskVersion {
    my ($self, $module) = @_;

    my $logger = $self->{logger};

    if (!$module->require()) {
        $logger->debug2("module $module does not compile: $@") if $logger;
        return;
    }

    if (!$module->isa('FusionInventory::Agent::Task')) {
        $logger->debug2("module $module is not a task") if $logger;
        return;
    }

    my $version;
    {
        no strict 'refs';  ## no critic
        $version = ${$module . '::VERSION'};
    }

    return $version;
}

sub _isAlreadyRunning {
    my ($self, $pidfile) = @_;

    Proc::PID::File->require();
    if ($EVAL_ERROR) {
        $self->{logger}->debug(
            'Proc::PID::File unavailable, unable to check for running agent'
        );
        return 0;
    }

    my $pid = Proc::PID::File->new();
    $pid->{path} = $pidfile;
    return $pid->alive();
}

sub _loadState {
    my ($self) = @_;

    my $data = $self->{storage}->restore(name => 'FusionInventory-Agent');

    $self->{deviceid} = $data->{deviceid} if $data->{deviceid};
}

sub _saveState {
    my ($self) = @_;

    $self->{storage}->save(
        name => 'FusionInventory-Agent',
        data => {
            deviceid => $self->{deviceid},
        }
    );
}

# compute an unique agent identifier, based on host name and current time
sub _computeDeviceId {
    my $hostname = getHostname();

    my ($year, $month , $day, $hour, $min, $sec) =
        (localtime (time))[5, 4, 3, 2, 1, 0];

    return sprintf "%s-%02d-%02d-%02d-%02d-%02d-%02d",
        $hostname, $year + 1900, $month + 1, $day, $hour, $min, $sec;
}

sub _appendElementsNotAlreadyInList {
    my ($list, $elements, $logger) = @_;

    if (! UNIVERSAL::isa($list, 'ARRAY')) {
        $logger->error('_appendElementsNotAlreadyInList(): first argument is not an ARRAY ref');
        return $list;
    }
    if (UNIVERSAL::isa($elements, 'HASH')) {
        @$elements = keys %$elements;
    } elsif (! UNIVERSAL::isa($elements, 'ARRAY')) {
        $logger->error('_appendElementsNotAlreadyInList(): second argument is neither an ARRAY ref nor a HASH ref');
        return $list;
    }

    my %list = map { $_ => $_ } @$list;
    # we want to add elements only once, so we ensure that there are no duplicates
    my %elements = map { $_ => 1 } @$elements;
    @$elements = keys %elements;

    # union of list AND elements which are NOT in list
    my @newList = (@$list, grep( !defined($list{$_}), @$elements));

    return @newList;
}

sub computeTaskExecutionPlan {
    my ($self, @availableTasksNames, $logger) = @_;

    if (! defined($self->{config}) || !(UNIVERSAL::isa($self->{config}, 'FusionInventory::Agent::Config'))) {
        $logger->error("no config found in agent. Can't compute tasks execution plan");
        return;
    }

    my @executionPlan = ();
    if ($self->{config}->isParamArrayAndFilled('tasks')) {
        $self->{logger}->debug('isParamArrayAndFilled(\'tasks\') : true');
        @executionPlan = _makeExecutionPlan($self->{config}->{'tasks'}, @availableTasksNames, $logger);
    } else {
        $self->{logger}->debug('isParamArrayAndFilled(\'tasks\') : false');
        @executionPlan = @availableTasksNames;
    }

    return @executionPlan;
}

sub _makeExecutionPlan {
    my ($sortedTasks, @availableTasksNames, $logger) = @_;

    my $sortedTasksCloned = dclone $sortedTasks;
    my $task = shift @$sortedTasksCloned;
    my @executionPlan = ();
    my %available = map { $_ => 1 } @availableTasksNames;

    while (defined $task) {
        if ($task eq $CONTINUE_WORD) {
            last;
        }
        if ( defined($available{$task})) {
            push @executionPlan, $task;
        }
        $task = shift @$sortedTasksCloned;
    }
    if ( defined($task) && $task eq $CONTINUE_WORD) {
        # we append all other available tasks
        @executionPlan = _appendElementsNotAlreadyInList(\@executionPlan, \@availableTasksNames, $logger);
    }

    return @executionPlan;
}

sub getTasksExecutionPlan {
    my ($self) = @_;

    return $self->{tasksExecutionPlan};
}

1;
__END__

=head1 NAME

FusionInventory::Agent - Fusion Inventory agent

=head1 DESCRIPTION

This is the agent object.

=head1 METHODS

=head2 new(%params)

The constructor. The following parameters are allowed, as keys of the %params
hash:

=over

=item I<confdir>

the configuration directory.

=item I<datadir>

the read-only data directory.

=item I<vardir>

the read-write data directory.

=item I<options>

the options to use.

=back

=head2 init()

Initialize the agent.

=head2 run()

Run the agent.

=head2 terminate()

Terminate the agent.

=head2 getStatus()

Get the current agent status.

=head2 getTargets()

Get all targets.

=head2 getAvailableTasks()

Get all available tasks found on the system, as a list of module / version
pairs:

%tasks = (
    'Foo' => x,
    'Bar' => y,
);

=head1 LICENSE

This software is licensed under the terms of GPLv2+, see LICENSE file for
details.
