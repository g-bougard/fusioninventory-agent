#!/usr/bin/perl

use strict;
use warnings;
use lib 't/lib';

use Test::Deep;
use Test::Exception;
use Test::More;
use Test::NoWarnings;

use FusionInventory::Test::Inventory;
use FusionInventory::Agent::Task::Inventory::Linux::Storages::Megacli;

my %pdlist_tests = (
    set1_PDlist => {
        '1' => {
            'Successful diagnostics completion on ' => 'N/A',
            'Non Coerced Size' => '223.070 GB [0x1be244b0 Sectors]',
            'Media Type' => 'Solid State Device',
            'PD Type' => 'SATA',
            'Coerced Size' => '223.0 GB [0x1be00000 Sectors]',
            'Sequence Number' => '2',
            'Drive' => 'Not Certified',
            'SAS Address(0)' => '0x4433221104000000',
            'Locked' => 'Unlocked',
            'Sector Size' => '0',
            'Other Error Count' => '0',
            'Drive is formatted for PI information' => 'No',
            'Device Speed' => '6.0Gb/s',
            'Port\'s Linkspeed' => '6.0Gb/s',
            'Firmware state' => 'Online, Spun Up',
            'Drive\'s position' => 'DiskGroup: 0, Span: 0, Arm: 0',
            'Link Speed' => '6.0Gb/s',
            'Needs EKM Attention' => 'No',
            'Raw Size' => '223.570 GB [0x1bf244b0 Sectors]',
            'WWN' => '55cd2e40000ceb98',
            'Last Predictive Failure Event Seq Number' => '0',
            'Foreign State' => 'None',
            'Device Firmware Level' => '400i',
            'PI Eligibility' => 'No',
            'Connected Port Number' => '0(path0)',
            'Inquiry Data' => 'CVCV31700005240FGN  INTEL SSDSC2CW240A3                     400i',
            'Secured' => 'Unsecured',
            'Port status' => 'Active',
            'Media Error Count' => '0',
            'Drive has flagged a S.M.A.R.T alert ' => 'No',
            'Drive Temperature ' => '30C (86.00 F)',
            'FDE Enable' => 'Disable',
            'Predictive Failure Count' => '0',
            'Enclosure position' => '1',
            'Device Id' => '0',
            'PI' => 'No PI',
            'Enclosure Device ID' => '32',
            'Slot Number' => '0',
            'Shield Counter' => '0',
            'FDE Capable' => 'Not Capable'
        },
        '2' => {
            'Successful diagnostics completion on ' => 'N/A',
            'Exit Code' => '0x00',
            'Non Coerced Size' => '223.070 GB [0x1be244b0 Sectors]',
            'Media Type' => 'Solid State Device',
            'PD Type' => 'SATA',
            'Sequence Number' => '2',
            'Coerced Size' => '223.0 GB [0x1be00000 Sectors]',
            'Drive' => 'Not Certified',
            'SAS Address(0)' => '0x4433221105000000',
            'Locked' => 'Unlocked',
            'Sector Size' => '0',
            'Drive is formatted for PI information' => 'No',
            'Other Error Count' => '0',
            'Port\'s Linkspeed' => '6.0Gb/s',
            'Device Speed' => '6.0Gb/s',
            'Firmware state' => 'Online, Spun Up',
            'Drive\'s position' => 'DiskGroup: 0, Span: 0, Arm: 1',
            'Raw Size' => '223.570 GB [0x1bf244b0 Sectors]',
            'Needs EKM Attention' => 'No',
            'Link Speed' => '6.0Gb/s',
            'Foreign State' => 'None',
            'Last Predictive Failure Event Seq Number' => '0',
            'Device Firmware Level' => '400i',
            'WWN' => '55cd2e40000c841a',
            'PI Eligibility' => 'No',
            'Port status' => 'Active',
            'Secured' => 'Unsecured',
            'Inquiry Data' => 'CVCV3165014E240FGN  INTEL SSDSC2CW240A3                     400i',
            'Connected Port Number' => '1(path0)',
            'Media Error Count' => '0',
            'Drive has flagged a S.M.A.R.T alert ' => 'No',
            'Predictive Failure Count' => '0',
            'FDE Enable' => 'Disable',
            'Drive Temperature ' => '30C (86.00 F)',
            'Enclosure position' => '1',
            'Device Id' => '1',
            'Enclosure Device ID' => '32',
            'PI' => 'No PI',
            'Shield Counter' => '0',
            'Slot Number' => '1',
            'FDE Capable' => 'Not Capable'
        }
    },
    set2_PDlist => {
        '2' => {
            'Drive has flagged a S.M.A.R.T alert ' => 'No',
            'Media Error Count' => '0',
            'Connected Port Number' => '0(path0)',
            'Inquiry Data' => 'HGST    HUC101212CSS600 U5E0KZGMA50E',
            'Port status' => 'Active',
            'Secured' => 'Unsecured',
            'PI Eligibility' => 'No',
            'WWN' => '5000CCA01D2324CB',
            'Device Firmware Level' => 'U5E0',
            'Foreign State' => 'None',
            'Last Predictive Failure Event Seq Number' => '0',
            'FDE Capable' => 'Not Capable',
            'Slot Number' => '1',
            'Shield Counter' => '0',
            'PI' => 'No PI',
            'Enclosure Device ID' => '32',
            'Device Id' => '1',
            'Enclosure position' => '1',
            'Drive Temperature ' => '31C (87.80 F)',
            'FDE Enable' => 'Disable',
            'Predictive Failure Count' => '0',
            'PD Type' => 'SAS',
            'Coerced Size' => '1.090 TB [0x8ba80000 Sectors]',
            'Sequence Number' => '2',
            'Media Type' => 'Hard Disk Device',
            'Non Coerced Size' => '1.090 TB [0x8baa0cb0 Sectors]',
            'Successful diagnostics completion on ' => 'N/A',
            'Link Speed' => '6.0Gb/s',
            'SAS Address(1)' => '0x0',
            'Needs EKM Attention' => 'No',
            'Raw Size' => '1.090 TB [0x8bba0cb0 Sectors]',
            'Drive\'s position' => 'DiskGroup: 0, Span: 0, Arm: 1',
            'Firmware state' => 'Online, Spun Up',
            'Device Speed' => '6.0Gb/s',
            'Port\'s Linkspeed' => 'Unknown',
            'Other Error Count' => '0',
            'Drive is formatted for PI information' => 'No',
            'Locked' => 'Unlocked',
            'Sector Size' => '0',
            'SAS Address(0)' => '0x5000cca01d2324c9'
        },
        '4' => {
            'SAS Address(0)' => '0x5000cca01d232651',
            'Sector Size' => '0',
            'Locked' => 'Unlocked',
            'Other Error Count' => '0',
            'Drive is formatted for PI information' => 'No',
            'Device Speed' => '6.0Gb/s',
            'Port\'s Linkspeed' => 'Unknown',
            'Firmware state' => 'Online, Spun Up',
            'Drive\'s position' => 'DiskGroup: 0, Span: 1, Arm: 1',
            'Link Speed' => '6.0Gb/s',
            'Raw Size' => '1.090 TB [0x8bba0cb0 Sectors]',
            'SAS Address(1)' => '0x0',
            'Needs EKM Attention' => 'No',
            'Successful diagnostics completion on ' => 'N/A',
            'Non Coerced Size' => '1.090 TB [0x8baa0cb0 Sectors]',
            'Media Type' => 'Hard Disk Device',
            'PD Type' => 'SAS',
            'Coerced Size' => '1.090 TB [0x8ba80000 Sectors]',
            'Sequence Number' => '2',
            'FDE Enable' => 'Disable',
            'Drive Temperature ' => '31C (87.80 F)',
            'Predictive Failure Count' => '0',
            'Enclosure position' => '1',
            'Device Id' => '3',
            'PI' => 'No PI',
            'Enclosure Device ID' => '32',
            'Slot Number' => '3',
            'Shield Counter' => '0',
            'FDE Capable' => 'Not Capable',
            'WWN' => '5000CCA01D232653',
            'Last Predictive Failure Event Seq Number' => '0',
            'Foreign State' => 'None',
            'Device Firmware Level' => 'U5E0',
            'PI Eligibility' => 'No',
            'Inquiry Data' => 'HGST    HUC101212CSS600 U5E0KZGMA85E',
            'Connected Port Number' => '0(path0)',
            'Secured' => 'Unsecured',
            'Port status' => 'Active',
            'Media Error Count' => '0',
            'Drive has flagged a S.M.A.R.T alert ' => 'No'
        },
        '6' => {
            'PD Type' => 'SAS',
            'Coerced Size' => '1.090 TB [0x8ba80000 Sectors]',
            'Sequence Number' => '2',
            'Non Coerced Size' => '1.090 TB [0x8baa0cb0 Sectors]',
            'Media Type' => 'Hard Disk Device',
            'Successful diagnostics completion on ' => 'N/A',
            'Drive\'s position' => 'DiskGroup: 0, Span: 2, Arm: 1',
            'Link Speed' => '6.0Gb/s',
            'Needs EKM Attention' => 'No',
            'SAS Address(1)' => '0x0',
            'Raw Size' => '1.090 TB [0x8bba0cb0 Sectors]',
            'Device Speed' => '6.0Gb/s',
            'Port\'s Linkspeed' => 'Unknown',
            'Firmware state' => 'Online, Spun Up',
            'Locked' => 'Unlocked',
            'Sector Size' => '0',
            'Other Error Count' => '0',
            'Drive is formatted for PI information' => 'No',
            'SAS Address(0)' => '0x5000cca01d21449d',
            'Drive has flagged a S.M.A.R.T alert ' => 'No',
            'Media Error Count' => '0',
            'Connected Port Number' => '0(path0)',
            'Inquiry Data' => 'HGST    HUC101212CSS600 U5E0KZGL95PE',
            'Secured' => 'Unsecured',
            'Port status' => 'Active',
            'PI Eligibility' => 'No',
            'WWN' => '5000CCA01D21449F',
            'Foreign State' => 'None',
            'Device Firmware Level' => 'U5E0',
            'Last Predictive Failure Event Seq Number' => '0',
            'Slot Number' => '5',
            'Shield Counter' => '0',
            'FDE Capable' => 'Not Capable',
            'Device Id' => '5',
            'PI' => 'No PI',
            'Enclosure Device ID' => '32',
            'Drive Temperature ' => '30C (86.00 F)',
            'FDE Enable' => 'Disable',
            'Predictive Failure Count' => '0',
            'Enclosure position' => '1'
        },
        '10' => {
            'Sequence Number' => '2',
            'Coerced Size' => '1.090 TB [0x8ba80000 Sectors]',
            'PD Type' => 'SAS',
            'Exit Code' => '0x00',
            'Non Coerced Size' => '1.090 TB [0x8baa0cb0 Sectors]',
            'Media Type' => 'Hard Disk Device',
            'Successful diagnostics completion on ' => 'N/A',
            'Drive\'s position' => 'DiskGroup: 0, Span: 4, Arm: 1',
            'SAS Address(1)' => '0x0',
            'Needs EKM Attention' => 'No',
            'Raw Size' => '1.090 TB [0x8bba0cb0 Sectors]',
            'Link Speed' => '6.0Gb/s',
            'Port\'s Linkspeed' => 'Unknown',
            'Device Speed' => '6.0Gb/s',
            'Firmware state' => 'Online, Spun Up',
            'Locked' => 'Unlocked',
            'Sector Size' => '0',
            'Drive is formatted for PI information' => 'No',
            'Other Error Count' => '0',
            'SAS Address(0)' => '0x5000cca01d218e25',
            'Media Error Count' => '0',
            'Drive has flagged a S.M.A.R.T alert ' => 'No',
            'Secured' => 'Unsecured',
            'Port status' => 'Active',
            'Connected Port Number' => '0(path0)',
            'Inquiry Data' => 'HGST    HUC101212CSS600 U5E0KZGLG2HE',
            'PI Eligibility' => 'No',
            'Device Firmware Level' => 'U5E0',
            'Foreign State' => 'None',
            'Last Predictive Failure Event Seq Number' => '0',
            'WWN' => '5000CCA01D218E27',
            'Shield Counter' => '0',
            'Slot Number' => '9',
            'FDE Capable' => 'Not Capable',
            'Device Id' => '9',
            'Enclosure Device ID' => '32',
            'PI' => 'No PI',
            'Predictive Failure Count' => '0',
            'FDE Enable' => 'Disable',
            'Drive Temperature ' => '30C (86.00 F)',
            'Enclosure position' => '1'
        },
        '3' => {
            'FDE Capable' => 'Not Capable',
            'Shield Counter' => '0',
            'Slot Number' => '2',
            'Enclosure Device ID' => '32',
            'PI' => 'No PI',
            'Device Id' => '2',
            'Enclosure position' => '1',
            'Predictive Failure Count' => '0',
            'Drive Temperature ' => '31C (87.80 F)',
            'FDE Enable' => 'Disable',
            'Drive has flagged a S.M.A.R.T alert ' => 'No',
            'Media Error Count' => '0',
            'Port status' => 'Active',
            'Secured' => 'Unsecured',
            'Connected Port Number' => '0(path0)',
            'Inquiry Data' => 'HGST    HUC101212CSS600 U5E0KZGL949E',
            'PI Eligibility' => 'No',
            'Device Firmware Level' => 'U5E0',
            'Foreign State' => 'None',
            'Last Predictive Failure Event Seq Number' => '0',
            'WWN' => '5000CCA01D2143F3',
            'Raw Size' => '1.090 TB [0x8bba0cb0 Sectors]',
            'Needs EKM Attention' => 'No',
            'SAS Address(1)' => '0x0',
            'Link Speed' => '6.0Gb/s',
            'Drive\'s position' => 'DiskGroup: 0, Span: 1, Arm: 0',
            'Firmware state' => 'Online, Spun Up',
            'Port\'s Linkspeed' => 'Unknown',
            'Device Speed' => '6.0Gb/s',
            'Drive is formatted for PI information' => 'No',
            'Other Error Count' => '0',
            'Locked' => 'Unlocked',
            'Sector Size' => '0',
            'SAS Address(0)' => '0x5000cca01d2143f1',
            'Sequence Number' => '2',
            'PD Type' => 'SAS',
            'Coerced Size' => '1.090 TB [0x8ba80000 Sectors]',
            'Media Type' => 'Hard Disk Device',
            'Non Coerced Size' => '1.090 TB [0x8baa0cb0 Sectors]',
            'Successful diagnostics completion on ' => 'N/A'
        },
        '8' => {
            'FDE Capable' => 'Not Capable',
            'Slot Number' => '7',
            'Shield Counter' => '0',
            'PI' => 'No PI',
            'Enclosure Device ID' => '32',
            'Device Id' => '7',
            'Enclosure position' => '1',
            'FDE Enable' => 'Disable',
            'Drive Temperature ' => '31C (87.80 F)',
            'Predictive Failure Count' => '0',
            'Drive has flagged a S.M.A.R.T alert ' => 'No',
            'Media Error Count' => '0',
            'Inquiry Data' => 'HGST    HUC101212CSS600 U5E0KZGL7KNE',
            'Connected Port Number' => '0(path0)',
            'Port status' => 'Active',
            'Secured' => 'Unsecured',
            'PI Eligibility' => 'No',
            'WWN' => '5000CCA01D212C63',
            'Foreign State' => 'None',
            'Device Firmware Level' => 'U5E0',
            'Last Predictive Failure Event Seq Number' => '0',
            'Link Speed' => '6.0Gb/s',
            'SAS Address(1)' => '0x0',
            'Raw Size' => '1.090 TB [0x8bba0cb0 Sectors]',
            'Needs EKM Attention' => 'No',
            'Drive\'s position' => 'DiskGroup: 0, Span: 3, Arm: 1',
            'Firmware state' => 'Online, Spun Up',
            'Device Speed' => '6.0Gb/s',
            'Port\'s Linkspeed' => 'Unknown',
            'Other Error Count' => '0',
            'Drive is formatted for PI information' => 'No',
            'Locked' => 'Unlocked',
            'Sector Size' => '0',
            'SAS Address(0)' => '0x5000cca01d212c61',
            'PD Type' => 'SAS',
            'Coerced Size' => '1.090 TB [0x8ba80000 Sectors]',
            'Sequence Number' => '2',
            'Media Type' => 'Hard Disk Device',
            'Non Coerced Size' => '1.090 TB [0x8baa0cb0 Sectors]',
            'Successful diagnostics completion on ' => 'N/A'
        },
        '1' => {
            'PI Eligibility' => 'No',
            'WWN' => '5000CCA01D217F1B',
            'Foreign State' => 'None',
            'Device Firmware Level' => 'U5E0',
            'Last Predictive Failure Event Seq Number' => '0',
            'Media Error Count' => '0',
            'Drive has flagged a S.M.A.R.T alert ' => 'No',
            'Inquiry Data' => 'HGST    HUC101212CSS600 U5E0KZGLE2EE',
            'Connected Port Number' => '0(path0)',
            'Secured' => 'Unsecured',
            'Port status' => 'Active',
            'Enclosure position' => '1',
            'FDE Enable' => 'Disable',
            'Drive Temperature ' => '31C (87.80 F)',
            'Predictive Failure Count' => '0',
            'FDE Capable' => 'Not Capable',
            'Slot Number' => '0',
            'Shield Counter' => '0',
            'PI' => 'No PI',
            'Enclosure Device ID' => '32',
            'Device Id' => '0',
            'Successful diagnostics completion on ' => 'N/A',
            'PD Type' => 'SAS',
            'Coerced Size' => '1.090 TB [0x8ba80000 Sectors]',
            'Sequence Number' => '2',
            'Media Type' => 'Hard Disk Device',
            'Non Coerced Size' => '1.090 TB [0x8baa0cb0 Sectors]',
            'Other Error Count' => '0',
            'Drive is formatted for PI information' => 'No',
            'Locked' => 'Unlocked',
            'Sector Size' => '0',
            'SAS Address(0)' => '0x5000cca01d217f19',
            'Link Speed' => '6.0Gb/s',
            'SAS Address(1)' => '0x0',
            'Needs EKM Attention' => 'No',
            'Raw Size' => '1.090 TB [0x8bba0cb0 Sectors]',
            'Drive\'s position' => 'DiskGroup: 0, Span: 0, Arm: 0',
            'Firmware state' => 'Online, Spun Up',
            'Device Speed' => '6.0Gb/s',
            'Port\'s Linkspeed' => 'Unknown'
        },
        '9' => {
            'Media Error Count' => '0',
            'Drive has flagged a S.M.A.R.T alert ' => 'No',
            'Inquiry Data' => 'HGST    HUC101212CSS600 U5E0KZGLKP8E',
            'Connected Port Number' => '0(path0)',
            'Secured' => 'Unsecured',
            'Port status' => 'Active',
            'PI Eligibility' => 'No',
            'WWN' => '5000CCA01D21C44B',
            'Foreign State' => 'None',
            'Device Firmware Level' => 'U5E0',
            'Last Predictive Failure Event Seq Number' => '0',
            'Slot Number' => '8',
            'Shield Counter' => '0',
            'FDE Capable' => 'Not Capable',
            'Device Id' => '8',
            'PI' => 'No PI',
            'Enclosure Device ID' => '32',
            'Drive Temperature ' => '30C (86.00 F)',
            'FDE Enable' => 'Disable',
            'Predictive Failure Count' => '0',
            'Enclosure position' => '1',
            'Coerced Size' => '1.090 TB [0x8ba80000 Sectors]',
            'PD Type' => 'SAS',
            'Sequence Number' => '2',
            'Non Coerced Size' => '1.090 TB [0x8baa0cb0 Sectors]',
            'Media Type' => 'Hard Disk Device',
            'Successful diagnostics completion on ' => 'N/A',
            'Drive\'s position' => 'DiskGroup: 0, Span: 4, Arm: 0',
            'Link Speed' => '6.0Gb/s',
            'Needs EKM Attention' => 'No',
            'SAS Address(1)' => '0x0',
            'Raw Size' => '1.090 TB [0x8bba0cb0 Sectors]',
            'Device Speed' => '6.0Gb/s',
            'Port\'s Linkspeed' => 'Unknown',
            'Firmware state' => 'Online, Spun Up',
            'Sector Size' => '0',
            'Locked' => 'Unlocked',
            'Other Error Count' => '0',
            'Drive is formatted for PI information' => 'No',
            'SAS Address(0)' => '0x5000cca01d21c449'
        },
        '5' => {
            'Media Type' => 'Hard Disk Device',
            'Non Coerced Size' => '1.090 TB [0x8baa0cb0 Sectors]',
            'PD Type' => 'SAS',
            'Sequence Number' => '2',
            'Coerced Size' => '1.090 TB [0x8ba80000 Sectors]',
            'Successful diagnostics completion on ' => 'N/A',
            'Firmware state' => 'Online, Spun Up',
            'Device Speed' => '6.0Gb/s',
            'Port\'s Linkspeed' => 'Unknown',
            'Link Speed' => '6.0Gb/s',
            'SAS Address(1)' => '0x0',
            'Needs EKM Attention' => 'No',
            'Raw Size' => '1.090 TB [0x8bba0cb0 Sectors]',
            'Drive\'s position' => 'DiskGroup: 0, Span: 2, Arm: 0',
            'SAS Address(0)' => '0x5000cca01d21bcc5',
            'Other Error Count' => '0',
            'Drive is formatted for PI information' => 'No',
            'Locked' => 'Unlocked',
            'Sector Size' => '0',
            'Inquiry Data' => 'HGST    HUC101212CSS600 U5E0KZGLK5SE',
            'Connected Port Number' => '0(path0)',
            'Port status' => 'Active',
            'Secured' => 'Unsecured',
            'Media Error Count' => '0',
            'Drive has flagged a S.M.A.R.T alert ' => 'No',
            'WWN' => '5000CCA01D21BCC7',
            'Foreign State' => 'None',
            'Device Firmware Level' => 'U5E0',
            'Last Predictive Failure Event Seq Number' => '0',
            'PI Eligibility' => 'No',
            'PI' => 'No PI',
            'Enclosure Device ID' => '32',
            'Device Id' => '4',
            'FDE Capable' => 'Not Capable',
            'Slot Number' => '4',
            'Shield Counter' => '0',
            'Enclosure position' => '1',
            'FDE Enable' => 'Disable',
            'Drive Temperature ' => '31C (87.80 F)',
            'Predictive Failure Count' => '0'
        },
        '7' => {
            'PD Type' => 'SAS',
            'Coerced Size' => '1.090 TB [0x8ba80000 Sectors]',
            'Sequence Number' => '2',
            'Media Type' => 'Hard Disk Device',
            'Non Coerced Size' => '1.090 TB [0x8baa0cb0 Sectors]',
            'Successful diagnostics completion on ' => 'N/A',
            'Link Speed' => '6.0Gb/s',
            'Needs EKM Attention' => 'No',
            'Raw Size' => '1.090 TB [0x8bba0cb0 Sectors]',
            'SAS Address(1)' => '0x0',
            'Drive\'s position' => 'DiskGroup: 0, Span: 3, Arm: 0',
            'Firmware state' => 'Online, Spun Up',
            'Device Speed' => '6.0Gb/s',
            'Port\'s Linkspeed' => 'Unknown',
            'Other Error Count' => '0',
            'Drive is formatted for PI information' => 'No',
            'Sector Size' => '0',
            'Locked' => 'Unlocked',
            'SAS Address(0)' => '0x5000cca01d214295',
            'Drive has flagged a S.M.A.R.T alert ' => 'No',
            'Media Error Count' => '0',
            'Inquiry Data' => 'HGST    HUC101212CSS600 U5E0KZGL91HE',
            'Connected Port Number' => '0(path0)',
            'Port status' => 'Active',
            'Secured' => 'Unsecured',
            'PI Eligibility' => 'No',
            'WWN' => '5000CCA01D214297',
            'Device Firmware Level' => 'U5E0',
            'Foreign State' => 'None',
            'Last Predictive Failure Event Seq Number' => '0',
            'FDE Capable' => 'Not Capable',
            'Slot Number' => '6',
            'Shield Counter' => '0',
            'PI' => 'No PI',
            'Enclosure Device ID' => '32',
            'Device Id' => '6',
            'Enclosure position' => '1',
            'Drive Temperature ' => '31C (87.80 F)',
            'FDE Enable' => 'Disable',
            'Predictive Failure Count' => '0'
        }
    },
);

my %summary_tests = (
    set1_ShowSummary => {
        '1' => {
            'slot' => '1',
            'Power State' => 'Active',
            'Product Id' => 'INTEL SSDSC2CW24',
            'Vendor Id' => 'ATA',
            'encl_pos' => '1',
            'encl_id' => 0,
            'State' => 'Online',
            'Disk Type' => 'SATA,Solid State Device',
            'Capacity' => '223.0 GB'
        },
        '0' => {
            'State' => 'Online',
            'encl_id' => 0,
            'Disk Type' => 'SATA,Solid State Device',
            'Capacity' => '223.0 GB',
            'Power State' => 'Active',
            'slot' => '0',
            'Product Id' => 'INTEL SSDSC2CW24',
            'encl_pos' => '1',
            'Vendor Id' => 'ATA'
        }
    },
    set2_ShowSummary => {
        '7' => {
            'Vendor Id' => 'HGST',
            'encl_pos' => '1',
            'Product Id' => 'HUC101212CSS600',
            'Power State' => 'Active',
            'slot' => '7',
            'Capacity' => '1.090 TB',
            'Disk Type' => 'SAS,Hard Disk Device',
            'State' => 'Online',
            'encl_id' => 0
        },
        '1' => {
            'slot' => '1',
            'Power State' => 'Active',
            'encl_pos' => '1',
            'Vendor Id' => 'HGST',
            'Product Id' => 'HUC101212CSS600',
            'Disk Type' => 'SAS,Hard Disk Device',
            'encl_id' => 0,
            'State' => 'Online',
            'Capacity' => '1.090 TB'
        },
        '6' => {
            'Capacity' => '1.090 TB',
            'Disk Type' => 'SAS,Hard Disk Device',
            'State' => 'Online',
            'encl_id' => 0,
            'encl_pos' => '1',
            'Vendor Id' => 'HGST',
            'Product Id' => 'HUC101212CSS600',
            'slot' => '6',
            'Power State' => 'Active'
        },
        '5' => {
            'Product Id' => 'HUC101212CSS600',
            'encl_pos' => '1',
            'Vendor Id' => 'HGST',
            'slot' => '5',
            'Power State' => 'Active',
            'Capacity' => '1.090 TB',
            'State' => 'Online',
            'encl_id' => 0,
            'Disk Type' => 'SAS,Hard Disk Device'
        },
        '8' => {
            'Product Id' => 'HUC101212CSS600',
            'Vendor Id' => 'HGST',
            'encl_pos' => '1',
            'Power State' => 'Active',
            'slot' => '8',
            'Capacity' => '1.090 TB',
            'State' => 'Online',
            'encl_id' => 0,
            'Disk Type' => 'SAS,Hard Disk Device'
        },
        '3' => {
            'Power State' => 'Active',
            'slot' => '3',
            'Product Id' => 'HUC101212CSS600',
            'encl_pos' => '1',
            'Vendor Id' => 'HGST',
            'State' => 'Online',
            'encl_id' => 0,
            'Disk Type' => 'SAS,Hard Disk Device',
            'Capacity' => '1.090 TB'
        },
        '9' => {
            'Capacity' => '1.090 TB',
            'Disk Type' => 'SAS,Hard Disk Device',
            'encl_id' => 0,
            'State' => 'Online',
            'encl_pos' => '1',
            'Vendor Id' => 'HGST',
            'Product Id' => 'HUC101212CSS600',
            'Power State' => 'Active',
            'slot' => '9'
        },
        '2' => {
            'Disk Type' => 'SAS,Hard Disk Device',
            'encl_id' => 0,
            'State' => 'Online',
            'Capacity' => '1.090 TB',
            'Power State' => 'Active',
            'slot' => '2',
            'encl_pos' => '1',
            'Vendor Id' => 'HGST',
            'Product Id' => 'HUC101212CSS600'
        },
        '4' => {
            'Capacity' => '1.090 TB',
            'Disk Type' => 'SAS,Hard Disk Device',
            'State' => 'Online',
            'encl_id' => 0,
            'Vendor Id' => 'HGST',
            'encl_pos' => '1',
            'Product Id' => 'HUC101212CSS600',
            'Power State' => 'Active',
            'slot' => '4'
        },
        '0' => {
            'Disk Type' => 'SAS,Hard Disk Device',
            'encl_id' => 0,
            'State' => 'Online',
            'Capacity' => '1.090 TB',
            'slot' => '0',
            'Power State' => 'Active',
            'encl_pos' => '1',
            'Vendor Id' => 'HGST',
            'Product Id' => 'HUC101212CSS600'
        }
    },
);

my %enclosure_tests = (
    set1_EncInfo => {
        0 => 32,
    },
    set2_EncInfo => {
        0 => 32,
    },
);

plan tests =>
    (scalar keys %pdlist_tests) +
    (scalar keys %summary_tests) +
    (scalar keys %enclosure_tests) +
    1;

foreach my $test (keys %pdlist_tests) {
    my $file = "resources/linux/megacli/$test";
    my $results = FusionInventory::Agent::Task::Inventory::Linux::Storages::Megacli::_getPDlist(file => $file);
    cmp_deeply($results, $pdlist_tests{$test}, "$test: megacli -PDlist parsing");
}

foreach my $test (keys %summary_tests) {
    my $file = "resources/linux/megacli/$test";
    my $results = FusionInventory::Agent::Task::Inventory::Linux::Storages::Megacli::_getSummary(file => $file);
    cmp_deeply($results, $summary_tests{$test}, "$test: megacli -ShowSummary parsing");
}

foreach my $test (keys %enclosure_tests) {
    my $file = "resources/linux/megacli/$test";
    my $results = FusionInventory::Agent::Task::Inventory::Linux::Storages::Megacli::_getAdpEnclosure(file => $file);
    cmp_deeply($results, $enclosure_tests{$test}, "$test: megacli -EncInfo parsing");
}
