#!/usr/bin/expect

##
##    The Oracle Storage HCL Testkit is a suite of tests for certifying
##    storage with Oracle VM (OVM).
##    Copyright (C) 2014 Oracle Inc 
##
##    This file is part of the Oracle Storage HCL Testkit.
##
##    The Oracle Storage HCL Testkit is free software; you can redistribute 
##    it and/or modify it under the terms of the GNU General Public License 
##    as published by the Free Software Foundation; either version 2 of the 
##    License, or (at your option) any later version.
##
##    The Oracle Storage HCL Testkit is distributed in the hope that it will
##    be useful, but WITHOUT ANY WARRANTY; without even the implied warranty 
##    of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
##    GNU General Public License for more details.
##
##    You should have received a copy of the GNU General Public License
##    along with the Oracle Storage HCL Testkit.  If not; write to the 
##    Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, 
##    Boston, MA 02110-1301 USA. Or see <http://www.gnu.org/licenses/>.
##

set PWD [lindex $argv 7]

source $PWD/modules/iscsi_module.tcl
source $PWD/modules/common_storage.tcl

set ovmPassword [lindex $argv 0]
set ovmAgentPassword [lindex $argv 1]
set SAN_AdminPassword [lindex $argv 2]
set configFile [lindex $argv 3]
set datetime [lindex $argv 4]
set LOGDIR [lindex $argv 5]
set VERBOSE [lindex $argv 6]

set configData [parseConfig $configFile] 

if {[verifyConfigData "iscsi_vendor" $configData] == "False"} {
    send_user "\n\nMissing data from config file: $configFile\n"
    send_user "Please edit the config file and supply the missing data.\n"
    return 2
}

################ global variables #####################
set prompt "OVM> "
set send_human {.1 .3 1 .05 2}
set successMsg "Status: Success"
set failureMsg "Status: Failure"
set timeout 1800

########## externally defined variables ############
set adminServer [dict get $configData "adminServer"]
set ovmServerMasterIP [dict get $configData "ovmServerMasterIP"]
set ovmServerSlaveIP [dict get $configData "ovmServerSlaveIP"]

## Plugin Parameters
set PluginPrivateData [dict get $configData "PluginPrivateData"]

## Pool Parameters
set serverPoolIP [dict get $configData "serverPoolIP"]

## Install Media
set virtualCDROM_URL [dict get $configData "virtualCDROM_URL"]
set vmTemplateURL [dict get $configData "vmTemplateURL"]
set vmAssemblyURL [dict get $configData "vmAssemblyURL"]

## Network
set VM_Network [dict get $configData "VM_Network"]
set VM_Netmask [dict get $configData "VM_Netmask"]
set VM_NetworkPort [dict get $configData "VM_NetworkPort"]
set ovmServerMaster_vmnetworkIP [dict get $configData "ovmServerMaster_vmnetworkIP"] 
set ovmServerSlave_vmnetworkIP [dict get $configData "ovmServerSlave_vmnetworkIP"] 
                                                        
## Storage
set SAN_ServerName [dict get $configData "SAN_ServerName"]
set SAN_AccessHost [dict get $configData "SAN_AccessHost"]
set SAN_AccessPort [dict get $configData "SAN_AccessPort"]

set SAN_AdminHost [dict get $configData "SAN_AdminHost"]
set SAN_AdminUsername [dict get $configData "SAN_AdminUsername"]
set SAN_VolumeGroup [dict get $configData "SAN_VolumeGroup"]

set storageNetworkIP [dict get $configData "storageNetworkIP"]
set storageNetworkPort [dict get $configData "storageNetworkPort"]
set storageNetworkNetmask [dict get $configData "storageNetworkNetmask"]
set ovmServerMaster_storageIP [dict get $configData "ovmServerMaster_storageIP"]
set ovmServerSlave_storageIP [dict get $configData "ovmServerSlave_storageIP"]


##################### Local Variables ######################
## LUNs
set poolFSDiskID ""
set repoDiskID ""
set sharedDiskID ""

## Server Pool
append serverPoolName "iscsi_pool_" $datetime

## Repository Parameters
append repoName "iscsi_repo_" $datetime
append repoFSName "iscsi_repo_fs_" $datetime
append vdiskName1 "vdisk_" $datetime
append vdiskName2 "vdisk2_" $datetime

## VM Parameters
append vmName1 "VM1_" $datetime
append vmName2 "VM2_" $datetime
append vmName3 "VM_Clone1_" $datetime
append vmName4 "VM_Clone2_" $datetime

## Logging
append logfile $LOGDIR "iSCSI_Vendor_Plugin_Certification.log"
set testStep 0

## Test Status
set testList {VPIS-100 VPIS-101 VPIS-102 VPIS-103 VPIS-104 VPIS-105 VPIS-106 VPIS-201 VPIS-202 VPIS-203 VPIS-204 VPIS-205 VPIS-206 VPIS-207 VPIS-208}
array set testStatus {}
set testStatus(VPIS-100,status) "Not Run"
set testStatus(VPIS-101,status) "Not Run"
set testStatus(VPIS-102,status) "Not Run"
set testStatus(VPIS-103,status) "Not Run"
set testStatus(VPIS-104,status) "Not Run"
set testStatus(VPIS-105,status) "Not Run"
set testStatus(VPIS-106,status) "Not Run"
set testStatus(VPIS-201,status) "Not Run"
set testStatus(VPIS-202,status) "Not Run"
set testStatus(VPIS-203,status) "Not Run"
set testStatus(VPIS-204,status) "Not Run"
set testStatus(VPIS-205,status) "Not Run"
set testStatus(VPIS-206,status) "Not Run"
set testStatus(VPIS-207,status) "Not Run"
set testStatus(VPIS-208,status) "Not Run"

set is_iscsi "True"

#################################################################
##
##       Test Suite 2: iSCSI with Vendor Plugin
##
#################################################################

log_user 0
log_file -a $logfile


## Testcase VPIS-100
set testStatus(VPIS-100,status) "Failed"
printTestHeader "VPIS-100" "Discover OVM Servers"
#source whatever_the_test_name_is.tcl
set testStatus(VPIS-100,status) "Passed"


## Testcase VPIS-101
set testStatus(VPIS-101,status) "Failed"
printTestHeader "VPIS-101" "Create Access Groups"
#source $PWD/scripts/whatever_the_test_name_is.tcl
set testStatus(VPIS-101,status) "Passed"


## Testcase VPIS-102
set testStatus(VPIS-102,status) "Failed"
printTestHeader "VPIS-102" "Create LUNs"
#source $PWD/scripts/whatever_the_test_name_is.tcl
set testStatus(VPIS-102,status) "Passed"


## Testcase VPIS-103
set testStatus(VPIS-103,status) "Failed"
printTestHeader "VPIS-103" "Present LUNs to Access Groups"
#source $PWD/scripts/whatever_the_test_name_is.tcl
set testStatus(VPIS-103,status) "Passed"


## Testcase VPIS-104
set testStatus(VPIS-104,status) "Failed"
printTestHeader "VPIS-104" "Remove LUNs from Access Groups"
#source $PWD/scripts/whatever_the_test_name_is.tcl
set testStatus(VPIS-104,status) "Passed"


## Testcase VPIS-105
set testStatus(VPIS-105,status) "Failed"
printTestHeader "VPIS-105" "Present LUNs to both Access Groups"
#source $PWD/scripts/whatever_the_test_name_is.tcl
set testStatus(VPIS-105,status) "Passed"


## Testcase VPIS-106
set testStatus(VPIS-106,status) "Failed"
printTestHeader "VPIS-106" "Resize LUNs"
#source $PWD/scripts/whatever_the_test_name_is.tcl
set testStatus(VPIS-106,status) "Passed"


## Testcase VPIS-201
set testStatus(VPIS-201,status) "Failed"
printTestHeader "VPIS-201" "Create LUNs and Access Groups"
#source $PWD/scripts/whatever_the_test_name_is.tcl
set testStatus(VPIS-201,status) "Passed"


########## Repository and Server Pool creation changed
########## for 3.3 with iSCSI and FC luns.  See the generic
########## tests to see how to do this, or read the CLI doc.
## Testcase VPIS-202
set testStatus(VPIS-202,status) "Failed"
printTestHeader "VPIS-202" "Clustered Server Pool and Repository Creation"
#source $PWD/scripts/whatever_the_test_name_is.tcl
set testStatus(VPIS-202,status) "Passed"


## Testcase VPIS-203
set testStatus(VPIS-203,status) "Failed"
printTestHeader "VPIS-203" "Repository Operations"
#source $PWD/scripts/whatever_the_test_name_is.tcl
set testStatus(VPIS-203,status) "Passed"

########## I got rid of the template, assembly, and iso
########## name variables, because it's better to use the
########## id strings.  See how I made it work in the 
########## Generic tests.  
## Testcase VPIS-204
set testStatus(VPIS-204,status) "Failed"
printTestHeader "VPIS-204" "Create VM Guests"
#source $PWD/scripts/whatever_the_test_name_is.tcl
set testStatus(VPIS-204,status) "Passed"


########### in the OVM 3.2 testkit, VPIS 205-207 were combined to make 
########### the test flow more smoothly.  Can implement it that way
########### again, or break it out into the testcases as they are
########### actually described in the doc.  Your call.
 
## Testcase VPIS-205
set testStatus(VPIS-205,status) "Failed"
printTestHeader "VPIS-205" "Migrate Offline VM Guests and Start VMs"
#source $PWD/scripts/whatever_the_test_name_is.tcl
set testStatus(VPIS-205,status) "Passed"


## Testcase VPIS-206
set testStatus(VPIS-206,status) "Failed"
printTestHeader "VPIS-206" "Live Migrate VM Guests"
#source $PWD/scripts/whatever_the_test_name_is.tcl
set testStatus(VPIS-206,status) "Passed"


## Testcase VPIS-207
set testStatus(VPIS-207,status) "Failed"
printTestHeader "VPIS-207" "uspend/Resume/Stop VM Guests"
#source $PWD/scripts/whatever_the_test_name_is.tcl
set testStatus(VPIS-207,status) "Passed"


## Testcase VPIS-208
set testStatus(VPIS-208,status) "Failed"
printTestHeader "VPIS-208" "Clone VM Guests"
#source $PWD/scripts/whatever_the_test_name_is.tcl
set testStatus(VPIS-208,status) "Passed"




finishRun 0
