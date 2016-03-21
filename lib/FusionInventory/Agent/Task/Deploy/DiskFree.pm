package FusionInventory::Agent::Task::Deploy::DiskFree;

use strict;
use warnings;
use base 'Exporter';

use English qw(-no_match_vars);
use Parallel::ForkManager;
use FusionInventory::Agent::Tools;

use UNIVERSAL::require;

our @EXPORT = qw(
    getFreeSpace
);

sub getFreeSpace {
    my $freeSpace =
        $OSNAME eq 'MSWin32' ? _getFreeSpaceWindows(@_) :
        $OSNAME eq 'solaris' ? _getFreeSpaceSolaris(@_) :
        _getFreeSpace(@_);

    return $freeSpace;
}

sub _getFreeSpaceWindows {
    my (%params) = @_;

    my $logger = $params{logger};

    my $letter;
    if ($params{path} !~ /^(\w):/) {
        $logger->error("Path parse error: ".$params{path});
        return;
    }
    $letter = $1.':';

    my $freeSpace;

    # Fork to avoid a crash with needed not thread-safe Win32::OLE API
    my $pfm = Parallel::ForkManager->new(1);

    # Handle how we retrieve $freeSpace from worker thread
    $pfm->run_on_finish(
        sub {
            my ($pid, $exit, $ident, $signal, $core_dump, $dataref) = @_;
            if ($core_dump) {
                $logger->error("Failed to retrieve freespace");
                $logger->debug("Received $exit exit code and $signal signal");
            }
            $freeSpace = ref($dataref) eq 'SCALAR' ? ${$dataref} : 0 ;
        }
    );

    # Start the thread doing the job with Win32::OLE
    unless ($pfm->start('getFreeSpace')) {
        FusionInventory::Agent::Tools::Win32->require();
        if ($EVAL_ERROR) {
            $logger->error(
                "Failed to load FusionInventory::Agent::Tools::Win32: $EVAL_ERROR"
            );
            $pfm->finish(1);
        }

        foreach my $object (FusionInventory::Agent::Tools::Win32::getWMIObjects(
            moniker    => 'winmgmts:{impersonationLevel=impersonate,(security)}!//./',
            class      => 'Win32_LogicalDisk',
            properties => [ qw/Caption FreeSpace/ ]
        )) {
            next unless lc($object->{Caption}) eq lc($letter);
            my $t = $object->{FreeSpace};
            if ($t && $t =~ /(\d+)\d{6}$/) {
                $freeSpace = $1;
            }
        }
        $pfm->finish(0, \$freeSpace);
    }
    $pfm->wait_all_children;

    return $freeSpace;
}

sub _getFreeSpaceSolaris {
    my (%params) = @_;

    return unless -d $params{path};

    return getFirstMatch(
        command => "df -b $params{path}",
        pattern => qr/^\S+\s+(\d+)\d{3}[^\d]/,
        logger  => $params{logger}
    );
}

sub _getFreeSpace {
    my (%params) = @_;

    return unless -d $params{path};

    return getFirstMatch(
        command => "df -Pk $params{path}",
        pattern => qr/^\S+\s+\S+\s+\S+\s+(\d+)\d{3}[^\d]/,
        logger  => $params{logger}
    );
}

1;
