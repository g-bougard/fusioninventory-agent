#!/usr/bin/perl

use strict;
use warnings;
use lib 't/lib';

use English qw(-no_match_vars);
use List::Util qw(first);
use Test::More;
use Test::Exception;

use FusionInventory::Agent::Logger::Test;
use FusionInventory::Agent::HTTP::Client;
use FusionInventory::Test::Proxy;
use FusionInventory::Test::Server;
use FusionInventory::Test::Utils;

# Debug SSL negociation in case of failure
#$Net::SSLeay::trace = 1;

unsetProxyEnvVar();

my $port;

# API to find an available port
sub GetTestPort {
    $port = first { test_port($_) } 8080 .. 8090;
}

# API to return URL related to current server
sub GetTestRequest {
    return HTTP::Request->new(GET => "https://127.0.0.1:$port/public");
}

if (!GetTestPort()) {
    plan skip_all => 'no available port';
} elsif ($OSNAME eq 'MSWin32') {
    plan skip_all => 'non working test on Windows';
} elsif ($OSNAME eq 'darwin') {
    plan skip_all => 'non working test on MacOS';
} else {
    plan tests => 8;
}

my $ok = sub {
    my ($server, $cgi) = @_;

    print "HTTP/1.0 200 OK\r\n";
    print "\r\n";
    print "OK";
};

my $logger = FusionInventory::Agent::Logger::Test->new();

unless (-e "resources/ssl/crt/ca.pem") {
    print STDERR "Generating SSL certificates...\n";
    qx(cd resources/ssl ; ./generate.sh );
}

my $proxy = FusionInventory::Test::Proxy->new();
$proxy->background();

my $server;
my $unsafe_client = FusionInventory::Agent::HTTP::Client->new(
    logger       => $logger,
    no_ssl_check => 1,
);

my $secure_client = FusionInventory::Agent::HTTP::Client->new(
    logger       => $logger,
    ca_cert_file => 'resources/ssl/crt/ca.pem',
);

my $secure_proxy_client = FusionInventory::Agent::HTTP::Client->new(
    logger => $logger,
    proxy  => $proxy->url(),
    ca_cert_file => 'resources/ssl/crt/ca.pem',
);

# ensure the server get stopped even if an exception is thrown
$SIG{__DIE__}  = sub { $server->stop(); };

# trusted certificate, correct hostname
$server = FusionInventory::Test::Server->new(
    port     => GetTestPort(),
    ssl      => 1,
    crt      => 'resources/ssl/crt/good.pem',
    key      => 'resources/ssl/key/good.pem',
);
$server->set_dispatch({
    '/public'  => $ok,
});

undef $EVAL_ERROR;
eval {
    $server->background();
};
ok(!$EVAL_ERROR, "Server can be launched in background");

ok(
    $secure_client->request(GetTestRequest())->is_success(),
    'trusted certificate, correct hostname: connection success'
);

SKIP: {
skip "Known to fail, see: http://forge.fusioninventory.org/issues/1940", 1 unless $ENV{TEST_AUTHOR};
ok(
    $secure_proxy_client->request(GetTestRequest())->is_success(),
    'trusted certificate, correct hostname, through proxy: connection success'
);
}

$server->stop();
$proxy->stop();

# trusted certificate, alternate hostname
$server = FusionInventory::Test::Server->new(
    port     => GetTestPort(),
    ssl      => 1,
    crt      => 'resources/ssl/crt/alternate.pem',
    key      => 'resources/ssl/key/alternate.pem',
);
$server->set_dispatch({
    '/public'  => $ok,
});
$server->background();

SKIP: {
skip "LWP version too old, skipping", 1 unless $LWP::VERSION >= 6;
ok(
    $secure_client->request(GetTestRequest())->is_success(),
    'trusted certificate, alternate hostname: connection success'
);
}

$server->stop();

# trusted certificate, wrong hostname
$server = FusionInventory::Test::Server->new(
    port     => GetTestPort(),
    ssl      => 1,
    crt      => 'resources/ssl/crt/wrong.pem',
    key      => 'resources/ssl/key/wrong.pem',
);
$server->set_dispatch({
    '/public'  => $ok,
});
$server->background();

ok(
    $unsafe_client->request(GetTestRequest())->is_success(),
    'trusted certificate, wrong hostname, no check: connection success'
);

ok(
    !$secure_client->request(GetTestRequest())->is_success(),
    'trusted certificate, wrong hostname: connection failure'
);
$server->stop();

# untrusted certificate, correct hostname
$server = FusionInventory::Test::Server->new(
    port     => GetTestPort(),
    ssl      => 1,
    crt      => 'resources/ssl/crt/bad.pem',
    key      => 'resources/ssl/key/bad.pem',
);
$server->set_dispatch({
    '/public'  => $ok,
});
$server->background();

SKIP: {
skip "LWP version too old, skipping", 1 unless $LWP::VERSION >= 6;
ok(
    $unsafe_client->request(GetTestRequest())->is_success(),
    'untrusted certificate, correct hostname, no check: connection success'
);
}

ok(
    !$secure_client->request(GetTestRequest())->is_success(),
    'untrusted certificate, correct hostname: connection failure'
);

$server->stop();
