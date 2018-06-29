package FusionInventory::Agent::Task::Inventory::Linux::Bios;

use strict;
use warnings;

use parent 'FusionInventory::Agent::Task::Inventory::Module';

use English qw(-no_match_vars);

use FusionInventory::Agent::Tools;

# Only run this module if dmidecode has not been found
our $runMeIfTheseChecksFailed =
    ["FusionInventory::Agent::Task::Inventory::Generic::Dmidecode::Bios"];

# Follow dmidecode dmi_chassis_type() API:
# See https://github.com/mirror/dmidecode/blob/master/dmidecode.c#L545
my $chassis_types = [
    "",
    "Other",
    "Unknown",
    "Desktop",
    "Low Profile Desktop",
    "Pizza Box",
    "Mini Tower",
    "Tower",
    "Portable",
    "Laptop",
    "Notebook",
    "Hand Held",
    "Docking Station",
    "All in One",
    "Sub Notebook",
    "Space-Saving",
    "Lunch Box",
    "Main Server Chassis",
    "Expansion Chassis",
    "Sub Chassis",
    "Bus Expansion Chassis",
    "Peripheral Chassis",
    "RAID Chassis",
    "Rack Mount Chassis",
    "Sealed-case PC",
    "Multi-system",
    "CompactPCI",
    "AdvancedTCA",
    "Blade",
    "Blade Enclosing",
    "Tablet",
    "Convertible",
    "Detachable",
    "IoT Gateway",
    "Embedded PC",
    "Mini PC",
    "Stick PC",
];

sub isEnabled {
    return -d '/sys/class/dmi/id';
}

sub _dmi_info {
    my ($info) = @_;
    my $class = '/sys/class/dmi/id/'.$info;
    return if -d $class;
    return unless -e $class;
    return getFirstLine(file => $class);
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};

    my $bios     = {};
    my $hardware = {};

    my %bios_map = qw(
        BMANUFACTURER   bios_vendor
        BDATE           bios_date
        BVERSION        bios_version
        ASSETTAG        chassis_asset_tag
        SMODEL          product_name
        SMANUFACTURER   sys_vendor
        SSN             product_serial
        MMODEL          board_name
        MMANUFACTURER   board_vendor
        MSN             board_serial
    );

    foreach my $key (keys(%bios_map)) {
        my $value = _dmi_info($bios_map{$key});
        next unless defined($value);
        $bios->{$key} = $value;
    }

    # Fix issue #311: 'product_version' is a better 'SMODEL' for Lenovo systems
    my $system_version = _dmi_info('product_version');
    if ($system_version && $bios->{'SMANUFACTURER'} &&
            $bios->{'SMANUFACTURER'} =~ /^LENOVO$/i &&
            $system_version =~ /^(Think|Idea|Yoga|Netfinity|Netvista|Intelli)/i)
    {
        $bios->{'SMODEL'} = $system_version;
    }

    # Set Virtualbox VM S/N to UUID if found serial is '0'
    my $uuid = _dmi_info('product_uuid');
    if ($uuid && $bios->{MMODEL} && $bios->{MMODEL} eq "VirtualBox" &&
            $bios->{SSN} eq "0" && $bios->{MSN} eq "0")
    {
        $bios->{SSN} = $uuid;
    }

    $hardware->{UUID} = $uuid if $uuid;

    my $chassis_type = _dmi_info('chassis_type');
    if ($chassis_type && $chassis_types->[$chassis_type]) {
        $hardware->{CHASSIS_TYPE} = $chassis_types->[$chassis_type];
    }

    $inventory->setBios($bios);
    $inventory->setHardware($hardware);
}

1;
