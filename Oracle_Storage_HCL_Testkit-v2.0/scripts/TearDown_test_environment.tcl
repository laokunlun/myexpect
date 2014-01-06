#!/usr/bin/expect

##
##    The Oracle Storage HCL Testkit is a suite of tests for certifying
##    storage with Oracle VM (OVM).
##    Copyright (C) 2013 Oracle USA, Inc 
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

set PWD [lindex $argv 5]

source $PWD/modules/cleanup_module.tcl
source $PWD/modules/common_storage.tcl

set ovmPassword [lindex $argv 0]
set ovmAgentPassword [lindex $argv 1]
set configFile [lindex $argv 2]
set LOGDIR [lindex $argv 3]
set VERBOSE [lindex $argv 4]

set configData [parseConfig $configFile] 

if {[verifyConfigData "cleanup" $configData] == "False"} {
    send_user "\n\nMissing data from config file: $configFile\n"
    send_user "Please edit the config file and supply the missing data.\n"
    return 2
}


################ global variables #####################
set prompt "OVM> "
set send_human {.1 .3 1 .05 2}
set successMsg "Status: Success"
set failureMsg "Status: Failure"
set timeout 600
set testStep 0

########### template argument definitions #############
set ovmUser [dict get $configData "ovmUser"]
set adminServer [dict get $configData "adminServer"]
set ovmServerMasterIP [dict get $configData "ovmServerMasterIP"]
set ovmServerSlaveIP [dict get $configData "ovmServerSlaveIP"]

## Logging
append logfile $LOGDIR "Storage_HCL_Test_Environment_Cleanup.log"


#################### Execute Tear Down sequence ##################
log_user 0
OVMlogin
log_file -a $logfile


send_user "Attempting to clean up the Test Environment.\n\n"

send_user "\n\nAttempting to stop and delete all VMs....\n"
set status [deleteVM]
switch -- $status \
    "False" {
	finishRun 1
    } "None" {
	send_verbose "\nNo VMs were found.\nContinuing.\n\n"
    } "True" {
	send_verbose "\nSuccessfully deleted all VMs.  Continuing.\n\n"
    } default {
	send_user "An unexpected error has occurred: "
	finishRun 1
    }

sleep 3

send_user "\n\nAttempting to delete all Repositories and their contents....\n"
set status [deleteRepo]
switch -- $status \
    "False" {
	finishRun 1
    } "None" {
	send_verbose "\nNo repositories were found.\nContinuing.\n\n"
    } "True" {
	send_verbose "\nSuccessfully deleted all Repositories.\nContinuing.\n\n"
    } default {
	send_user "An unexpected error has occurred: "
	finishRun 1
    }

sleep 3

send_user "\n\nAttempting to delete all Server Pools....\n"
set status [deleteServerpool]
switch -- $status \
    "False" {
	finishRun 1
    } "None" {
	send_verbose "\nNo Server Pools were found.\nContinuing.\n\n"
    } "True" {
	send_verbose "\nSuccessfully deleted all Server Pools.\nContinuing.\n\n"
    } default {
	send_user "An unexpected error has occurred,"
	finishRun 1
    }

sleep 3

send_user "\n\nAttempting to delete the Servers....\n"
set status [deleteServers $ovmServerMasterIP $ovmServerSlaveIP]
switch -- $status \
    "False" {
	finishRun 1
    } "None" {
	send_verbose "\nNo Servers matching $ovmServerMasterIP or $ovmServerSlaveIP were found.\nContinuing.\n\n"
    } "True" {
	send_verbose "\nSuccessfully deleted $ovmServerMasterIP and $ovmServerSlaveIP.\nContinuing.\n\n"
    } default {
	send_user "An unexpected error has occurred,"
	finishRun 1
    }

sleep 4

send_user "\n\nAttempting to delete all vNICs....\n"
set status [deleteVNICs]
switch -- $status \
    "False" {
	finishRun 1
    } "None" {
	send_verbose "\nNo vNICs were found.\nContinuing.\n\n"
    } "True" {
	send_verbose "\nSuccessfully deleted all vNICs.\nContinuing.\n\n"
    } default {
	send_user "An unexpected error has occurred: "
	finishRun 1
    }

sleep 4

send_user "\n\nAttempting to delete all user defined SAN Servers\n"
set status [deleteSANServer]
switch -- $status \
    "False" {
	finishRun 1
    } "None" {
	send_verbose "\nNo SAN Servers were found.\nContinuing.\n\n"
    } "True" {
	send_verbose "\nSuccessfully deleted all SAN Servers.\nContinuing.\n\n"
    } default {
	send_user "An unexpected error has occurred: "
	finishRun 1
    }

sleep 4

send_user "\n\nAttempting to delete all user defined File Servers...\n"
set status [deleteFileServer]
switch -- $status \
    "False" {
	finishRun 1
    } "None" {
	send_verbose "\nNo File Servers were found.\nContinuing.\n\n"
    } "True" {
	send_verbose "\nSuccessfully deleted all File Servers.\nContinuing.\n\n"
    } default {
	send_user "An unexpected error has occurred: "
	finishRun 1
    }




send_user "\n\nAttempting to delete all defined Networks....\n"
set status [deleteNetwork]
switch -- $status \
    "False" {
	finishRun 1
    } "None" {
	send_verbose "\nNo Networks were found.\nContinuing.\n\n"
    } "True" {
	send_verbose "\nSuccessfully deleted all Networks.\nContinuing.\n\n"
    } default {
	send_user "An unexpected error has occurred: "
	finishRun 1
    }

send_user "\n\nAttempting to delete any Physical Disks that were left behind....\n"
set status [deleteStragglerLUNs]
switch -- $status \
    "False" {
	finishRun 1
    } "None" {
	send_verbose "\nNo straggler LUNs were found.\nContinuing.\n\n"
    } "True" {
	send_verbose "\nSuccessfully deleted all straggler LUNs.\nContinuing.\n\n"
    } default {
	send_user "An unexpected error has occurred: "
	finishRun 1
    }



send_user "\n\nCleanup script executed successfully.\n";
finishRun 0
