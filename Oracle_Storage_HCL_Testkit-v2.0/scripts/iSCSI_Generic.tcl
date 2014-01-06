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

set PWD [lindex $argv 6]

source $PWD/modules/iscsi_module.tcl
source $PWD/modules/common_storage.tcl

set ovmPassword [lindex $argv 0]
set ovmAgentPassword [lindex $argv 1]
set configFile [lindex $argv 2]
set datetime [lindex $argv 3]
set LOGDIR [lindex $argv 4]
set VERBOSE [lindex $argv 5]

set configData [parseConfig $configFile] 

if {[verifyConfigData "iscsi" $configData] == "False"} {
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
set ovmUser [dict get $configData "ovmUser"]
set adminServer [dict get $configData "adminServer"]
set ovmServerMasterIP [dict get $configData "ovmServerMasterIP"]
set ovmServerSlaveIP [dict get $configData "ovmServerSlaveIP"]

# Pool Parameters
set serverPoolIP [dict get $configData "serverPoolIP"]

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

set storageNetworkIP [dict get $configData "storageNetworkIP"]
set storageNetworkPort [dict get $configData "storageNetworkPort"]
set storageNetworkNetmask [dict get $configData "storageNetworkNetmask"]
set ovmServerMaster_storageIP [dict get $configData "ovmServerMaster_storageIP"]
set ovmServerSlave_storageIP [dict get $configData "ovmServerSlave_storageIP"]

## Install Media
set virtualCDROM_URL [dict get $configData "virtualCDROM_URL"]
set vmTemplateURL [dict get $configData "vmTemplateURL"]
set vmAssemblyURL [dict get $configData "vmAssemblyURL"]


###################### Local Variables ######################
## LUNs
set poolFSDiskID ""
set repoDiskID ""
set sharedDiskID ""

## Server Pool
append serverPoolName "iscsi_pool_" $datetime

## Repository Parameters
append repoName "iscsi_repo_" $datetime
append repoFSName "iscsi_repo_fs_" $datetime
append vdiskName1 "vdisk1_" $datetime
append vdiskName2 "vdisk2_" $datetime

## VM Parameters
append vmName1 "VM_iscsi1_" $datetime
append vmName2 "VM_iscsi2_" $datetime

## Logging
append logfile $LOGDIR "iSCSI_Generic_Plugin_Certification.log"
set testStep 0

## Test Status
set testList {GSIS-101 GSIS-201 GSIS-202 GSIS-203 GSIS-204 GSIS-301 GSIS-302 GSIS-303 GSIS-304 GSIS-305 GSIS-306 GSIS-307 GSIS-308 GSIS-309}
array set testStatus {}
set testStatus(GSIS-101,status) "Not Run"
set testStatus(GSIS-201,status) "UNSUPPORTED"
set testStatus(GSIS-202,status) "UNSUPPORTED"
set testStatus(GSIS-203,status) "UNSUPPORTED"
set testStatus(GSIS-204,status) "UNSUPPORTED"
set testStatus(GSIS-301,status) "Not Run"
set testStatus(GSIS-302,status) "Not Run"
set testStatus(GSIS-303,status) "Not Run"
set testStatus(GSIS-304,status) "Not Run"
set testStatus(GSIS-305,status) "Not Run"
set testStatus(GSIS-306,status) "Not Run"
set testStatus(GSIS-307,status) "Not Run"
set testStatus(GSIS-308,status) "Manual Test Case"
set testStatus(GSIS-309,status) "Manual Test Case"

set is_iscsi "True"

#################################################################
##
##       Test Suite 1: iSCSI with Generic Plugin
##
#################################################################

log_user 0
log_file -a $logfile

## Testcase GSIS-101
set testStatus(GSIS-101,status) "Failed"
send_user "\nHCL> At this time, the iSCSI generic plugin tests with CHAP disabled\n"
send_user "     will be executed.  Please ensure that your environment is configured\n"
send_user "     correctly, then when you are ready to begin, press Enter to resume: "
gets stdin data
printTestHeader "GSIS-101" "Discover OVM servers."
source $PWD/scripts/Generic-iscsi-setup.tcl
set testStatus(GSIS-101,status) "Passed"

### Testcase GSIS-301
set testStatus(GSIS-301,status) "Failed"
send_user "\nHCL> At this time, please map a 5G LUN to $masterName,\n"
send_user "     and then map a 10G LUN to $slaveName.\n"
send_user "     After the LUNs have been mapped, press Enter to resume: "
gets stdin data
printTestHeader "GSIS-301" "Discover LUNs mapped to each server."
source $PWD/scripts/Generic-map1.tcl
set testStatus(GSIS-301,status) "Passed"

## Testcase GSIS-302
set testStatus(GSIS-302,status) "Failed"
send_user "\n\nHCL> At this time, please resize the LUNs from the previous test.\n"
send_user "     Increase the LUN sizes to 7G and 12G, respectively.\n"
send_user "     Once the LUNs have been resized, press Enter to resume: "
gets stdin data
printTestHeader "GSIS-302" "Resize LUNs mapped to each server"
source $PWD/scripts/Generic-resize.tcl
set testStatus(GSIS-302,status) "Passed"

## Testcase GSIS-303
set testStatus(GSIS-303,status) "Failed"
send_user "\nHCL> At this time, please unmap the 7G and 12G LUNs from the previous\n"
send_user "     test.  After the LUNs have been unmapped, press Enter to resume: "
gets stdin data
printTestHeader "GSIS-303" "Unmap LUNs from each server"
source $PWD/scripts/Generic-unmap.tcl
set testStatus(GSIS-303,status) "Passed"

## Testcase GSIS-304
set testStatus(GSIS-304,status) "Failed"
send_user "\nHCL> At this time, please map four new LUNs to both servers.\n"
send_user "     The LUNs must be the following sizes: 2G, 5G, 10G, and 30G.\n"
send_user "     After the LUNs have been mapped, press Enter to resume: "
gets stdin data
printTestHeader "GSIS-304" "Map LUNs to both servers"
source $PWD/scripts/Generic-map2.tcl
set testStatus(GSIS-304,status) "Passed"

## Testcase GSIS-305
set testStatus(GSIS-305,status) "Failed"
send_user "\nHCL> At this time, please unmap the 2GB LUN from both servers, grow\n"
send_user "     the 5G LUN to 15G, and grow the 10G LUN to 20G.  The 30G LUN\n"
send_user "     remains the same size.  These are the required LUN sizes for\n"
send_user "     the remainder of the tests.  After the LUNs have been unmapped\n"
send_user "     and resized accordingly, press Enter to resume: "
gets stdin data
printTestHeader "GSIS-305" "Resize and unmap LUNs mapped to both servers"
source $PWD/scripts/Generic-map3.tcl
set testStatus(GSIS-305,status) "Passed"

## Testcase GSIS-306
set testStatus(GSIS-306,status) "Failed"
printTestHeader "GSIS-306" "Clustered Server Pool and Repository Creation"
source $PWD/scripts/Generic-repo.tcl
set testStatus(GSIS-306,status) "Passed"

## Testcase GSIS-307
set testStatus(GSIS-307,status) "Failed"
printTestHeader "GSIS-307" "Repository and VM Operations"
source $PWD/scripts/Generic-vmops.tcl
set testStatus(GSIS-307,status) "Passed"

finishRun 0


