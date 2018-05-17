package FusionInventory::Agent::Task::Inventory::Win32::Networks;

use strict;
use warnings;

use parent 'FusionInventory::Agent::Task::Inventory::Module';

use FusionInventory::Agent::Tools;
use FusionInventory::Agent::Tools::Network;
use FusionInventory::Agent::Tools::Win32;

sub isEnabled {
    my (%params) = @_;
    return 0 if $params{no_category}->{network};
    return 1;
}

sub isEnabledForRemote {
    my (%params) = @_;
    return 0 if $params{no_category}->{network};
    return 1;
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};
    my (@gateways, @dns, @ips);

    my $keys;

    foreach my $interface (getInterfaces()) {
        push @gateways, $interface->{IPGATEWAY}
            if $interface->{IPGATEWAY};
        push @dns, $interface->{dns}
            if $interface->{dns};

        push @ips, $interface->{IPADDRESS}
            if $interface->{IPADDRESS};

        # Cleanup not necessary values
        delete $interface->{dns};
        delete $interface->{DNSDomain};
        delete $interface->{GUID};

        # Don't reload registry keys between interfaces checks
        $keys = getRegistryKey(
            path   => "HKEY_LOCAL_MACHINE/SYSTEM/CurrentControlSet/Control/Network/{4D36E972-E325-11CE-BFC1-08002BE10318}",
            wmiopts => { # Only used for remote WMI optimization
                values  => [ qw/PnpInstanceID MediaSubType/ ]
            }
        ) unless $keys;

        $interface->{TYPE} = _getMediaType($interface->{PNPDEVICEID}, $keys);

        $inventory->addEntry(
            section => 'NETWORKS',
            entry   => $interface
        );
    }

    $inventory->setHardware({
        DEFAULTGATEWAY => join('/', uniq @gateways),
        DNS            => join('/', uniq @dns),
        IPADDR         => join('/', uniq @ips),
    });

}

sub _getMediaType {
    my ($deviceid, $keys) = @_;

    return unless defined $deviceid && $keys;

    my $subtype;

    foreach my $subkey_name (keys %{$keys}) {
        # skip variables
        next if $subkey_name =~ m{^/};
        my $subkey_connection = $keys->{$subkey_name}->{'Connection/'}
            or next;
        my $subkey_deviceid   = $subkey_connection->{'/PnpInstanceID'}
            or next;
        # Normalize PnpInstanceID
        $subkey_deviceid =~ s/\\\\/\\/g;
        if (lc($subkey_deviceid) eq lc($deviceid)) {
            $subtype = $subkey_connection->{'/MediaSubType'};
            last;
        }
    }

    return unless defined $subtype;

    return  $subtype eq '0x00000001' ? 'ethernet'  :
            $subtype eq '0x00000002' ? 'wifi'      :
            $subtype eq '0x00000007' ? 'bluetooth' :
                                       undef;
}

1;
