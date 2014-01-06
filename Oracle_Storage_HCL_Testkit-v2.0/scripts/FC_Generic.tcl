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

source $PWD/modules/fc_module.tcl
source $PWD/modules/common_storage.tcl

set ovmPassword [lindex $argv 0]
set ovmAgentPassword [lindex $argv 1]
set configFile [lindex $argv 2]
set datetime [lindex $argv 3]
set LOGDIR [lindex $argv 4]
set VERBOSE [lindex $argv 5]

set configData [parseConfig $configFile] 

if {[verifyConfigData "fc" $configData] == "False"} {
    send_user "\n\nMissing data from config file: $configFile\n"
    send_user "Please edit the config file and supply the missing data.\n"
    return 2
}


################ global variables #####################
set prompt "OVM> "
set send_human {.1 .3 1 .05 2}
set successMsg "Status: Success"
set failureMsg "Status: Failure"
set timeout 900

set poolFSDiskID ""
set repoDiskID ""
set sharedDiskID ""

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
set SAN_ServerName "Unmanaged FibreChannel Storage Array"

## Install Media
set virtualCDROM_URL [dict get $configData "virtualCDROM_URL"]
set vmTemplateURL [dict get $configData "vmTemplateURL"]
set vmAssemblyURL [dict get $configData "vmAssemblyURL"]


###################### Local Variables ######################
# Server Pool
append serverPoolName "fc_pool_" $datetime

# Repository Parameters
append repoName "fc_repo_" $datetime
append repoFSName "fc_repo_fs_" $datetime
append vdiskName1 "vdisk1_" $datetime
append vdiskName2 "vdisk2_" $datetime

## VM Parameters
append vmName1 "VM_fc1_" $datetime
append vmName2 "VM_fc2_" $datetime


## Logging
append logfile $LOGDIR "FibreChannel_Generic_Plugin_Certification.log"
set testStep 0

## Test Status
set testList {GSFC-101 GSFC-102 GSFC-103 GSFC-104 GSFC-105 GSFC-106 GSFC-107 GSFC-108 GSFC-109}
array set testStatus {}
set testStatus(GSFC-101,status) "Not Run"
set testStatus(GSFC-102,status) "Not Run"
set testStatus(GSFC-103,status) "Not Run"
set testStatus(GSFC-104,status) "Not Run"
set testStatus(GSFC-105,status) "Not Run"
set testStatus(GSFC-106,status) "Not Run"
set testStatus(GSFC-107,status) "Not Run"
set testStatus(GSFC-108,status) "Not Run"
set testStatus(GSFC-109,status) "Manual Test Case"
set testStatus(GSIS-110,status) "Manual Test Case"

set is_iscsi "False"

#################################################################
##
##       Test Suite 1: FibreChannel with Generic Plugin
##
#################################################################

log_user 0
log_file -a $logfile

## Testcase GSFC-101
set testStatus(GSFC-101,status) "Failed"
printTestHeader "GSFC-101" "Discover OVM servers."
source $PWD/scripts/Generic-fc-setup.tcl
set testStatus(GSFC-101,status) "Passed"

### Testcase GSFC-102
set testStatus(GSFC-102,status) "Failed"
send_user "\nHCL> At this time, please map a 5G LUN to $masterName,\n"
send_user "     and then map a 10G LUN to $slaveName.\n"
send_user "     After the LUNs have been mapped, press Enter to resume: "
gets stdin data
printTestHeader "GSFC-102" "Discover LUNs mapped to each server."
source $PWD/scripts/Generic-map1.tcl
set testStatus(GSFC-102,status) "Passed"

## Testcase GSFC-103
set testStatus(GSFC-103,status) "Failed"
send_user "\n\nHCL> At this time, please resize the LUNs from the previous test.\n"
send_user "     Increase the LUN sizes to 7G and 12G, respectively.\n"
send_user "     Once the LUNs have been resized, press Enter to resume: "
gets stdin data
printTestHeader "GSFC-103" "Resize LUNs mapped to each server"
source $PWD/scripts/Generic-resize.tcl
set testStatus(GSFC-103,status) "Passed"

## Testcase GSFC-104
set testStatus(GSFC-104,status) "Failed"
send_user "\nHCL> At this time, please unmap the 7G and 12G LUNs from the previous\n"
send_user "     test.  After the LUNs have been unmapped, press Enter to resume: "
gets stdin data
printTestHeader "GSFC-104" "Unmap LUNs from each server"
source $PWD/scripts/Generic-unmap.tcl
set testStatus(GSFC-104,status) "Passed"

## Testcase GSFC-105
set testStatus(GSFC-105,status) "Failed"
send_user "\nHCL> At this time, please map four new LUNs to both servers.\n"
send_user "     The LUNs must be the following sizes: 2G, 5G, 10G, and 30G.\n"
send_user "     After the LUNs have been mapped, press Enter to resume: "
gets stdin data
printTestHeader "GSFC-105" "Map LUNs to both servers"
source $PWD/scripts/Generic-map2.tcl
set testStatus(GSFC-105,status) "Passed"

## Testcase GSFC-106
set testStatus(GSFC-106,status) "Failed"
send_user "\nHCL> At this time, please unmap the 2GB LUN from both servers, grow\n"
send_user "     the 5G LUN to 15G, and grow the 10G LUN to 20G.  The 30G LUN\n"
send_user "     remains the same size.  These are the required LUN sizes for\n"
send_user "     the remainder of the tests.  After the LUNs have been unmapped\n"
send_user "     and resized accordingly, press Enter to resume: "
gets stdin data
printTestHeader "GSFC-106" "Resize and unmap LUNs mapped to both servers"
source $PWD/scripts/Generic-map3.tcl
set testStatus(GSFC-106,status) "Passed"

## Testcase GSFC-107
set testStatus(GSFC-107,status) "Failed"
printTestHeader "GSFC-107" "Clustered Server Pool and Repository Creation"
source $PWD/scripts/Generic-repo.tcl
set testStatus(GSFC-107,status) "Passed"

## Testcase GSFC-108
set testStatus(GSFC-108,status) "Failed"
printTestHeader "GSFC-108" "Repository and VM Operations"
source $PWD/scripts/Generic-vmops.tcl
set testStatus(GSFC-108,status) "Passed"

finishRun 0


