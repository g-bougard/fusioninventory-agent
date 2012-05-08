#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use FusionInventory::Agent::Task::NetInventory::Manufacturer;
use FusionInventory::Agent::Task::NetInventory::Manufacturer::Cisco;

# each item is an arrayref of three elements:
# - input data structure (ports list)
# - expected resulting data structure
# - test explication
my @devices_mac_addresses_tests = (
    [
        {
            0 => {
                MAC => 'X',
            }
        },
        {
            0 => {
                CONNECTIONS => {
                    CONNECTION => {
                        MAC => [ '00:1C:F6:C5:64:19' ]
                    }
                },
                MAC => 'X',
            }
        },
        'connected devices mac address retrieval'
    ],
    [
        {
            0 => {
                CONNECTIONS => {
                    CDP => 1,
                },
                MAC => 'X',
            }
        },
        {
            0 => {
                CONNECTIONS => {
                    CDP => 1,
                },
                MAC => 'X',
            }
        },
        'connected devices mac address retrieval, connected device found by CDP'
    ],
    [
        {
            0 => {
                MAC => '00:1C:F6:C5:64:19',
            }
        },
        {
            0 => {
                CONNECTIONS => {
                },
                MAC => '00:1C:F6:C5:64:19',
            }
        },
        'connected devices mac address retrieval, same mac address as the port'
    ],
);

# each item is an arrayref of three elements:
# - input data structure (ports list)
# - expected resulting data structure
# - test explication
my @devices_tests = (
    [
        {},
        {
            24 => {
                CONNECTIONS => {
                    CONNECTION => {
                        IP       => '192.168.20.139',
                        IFDESCR  => 'Port 1',
                        SYSDESCR => '7.4.9c',
                        SYSNAME  => 'SIPE05FB981A7A7',
                        MODEL    => 'Cisco IP Phone SPA508G',
                    },
                    CDP => 1,
                },
            },
        },
        'connected devices list retrieval'
    ],
);

plan tests => 
    scalar @devices_mac_addresses_tests +
    scalar @devices_tests;

my $walks = {
    cdpCacheDevicePort => {
        OID => '.1.3.6.1.4.1.9.9.23.1.2.1.1.7'
    },
    cdpCacheVersion => {
        OID => '.1.3.6.1.4.1.9.9.23.1.2.1.1.5'
    },
    cdpCacheDeviceId => {
        OID => '.1.3.6.1.4.1.9.9.23.1.2.1.1.6'
    },
    cdpCachePlatform => {
        OID => '.1.3.6.1.4.1.9.9.23.1.2.1.1.8'
    },
    dot1dBasePortIfIndex => {
        OID => '.1.3.6.1.2.17.1.4.1.2'
    },
    dot1dTpFdbAddress => {
        OID => '.1.3.6.1.2.1.17.4.3.1.1'
    },
    dot1dTpFdbPort => {
        OID => '.1.3.6.1.2.1.17.4.3.1.2'
    },
};

my $results = {
    cdpCacheAddress => {
        '.1.3.6.1.4.1.9.9.23.1.2.1.1.4.24.7' => '0xc0a8148b'
    },
    cdpCacheDevicePort => {
        '.1.3.6.1.4.1.9.9.23.1.2.1.1.7.24.7' => 'Port 1'
    },
    cdpCacheVersion => {
        '.1.3.6.1.4.1.9.9.23.1.2.1.1.5.24.7' => '7.4.9c'
    },
    cdpCacheDeviceId => {
        '.1.3.6.1.4.1.9.9.23.1.2.1.1.6.24.7' => 'SIPE05FB981A7A7'
    },
    cdpCachePlatform => {
        '.1.3.6.1.4.1.9.9.23.1.2.1.1.8.24.7' => 'Cisco IP Phone SPA508G'
    },
    VLAN => {
        1 => {
            dot1dTpFdbPort => {
                '.1.3.6.1.2.1.17.4.3.1.2.0.28.246.197.100.25' => 2307,
            },
            dot1dTpFdbAddress => {
                '.1.3.6.1.2.1.17.4.3.1.1.0.28.246.197.100.25' => '0x001CF6C56419',
            },
            dot1dBasePortIfIndex => {
                '.1.3.6.1.2.17.1.4.1.2.2307' => 0,
            }
        }
    }
};

foreach my $test (@devices_mac_addresses_tests) {
    FusionInventory::Agent::Task::NetInventory::Manufacturer::Cisco::setConnectedDevicesMacAddresses(
        results => $results, ports => $test->[0], walks => $walks, vlan_id => 1
    );

    is_deeply(
        $test->[0],
        $test->[1],
        $test->[2],
    );
}

foreach my $test (@devices_tests) {
    FusionInventory::Agent::Task::NetInventory::Manufacturer::setConnectedDevices(
        results => $results, ports => $test->[0], walks => $walks
    );

    is_deeply(
        $test->[0],
        $test->[1],
        $test->[2],
    );
}
