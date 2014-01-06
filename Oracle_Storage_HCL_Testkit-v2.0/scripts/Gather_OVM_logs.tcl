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

set PWD [lindex $argv 4]

source $PWD/modules/logging_module.tcl
source $PWD/modules/common_storage.tcl

set configFile [lindex $argv 0]
set ticket [lindex $argv 1]
set LOGDIR [lindex $argv 2]
set VERBOSE [lindex $argv 3]

set configData [parseConfig $configFile] 

if {[verifyConfigData "logging" $configData] == "False"} {
    send_user "\n\nMissing data from config file: $configFile\n"
    send_user "Please edit the config file and supply the missing data.\n"
    return 2
}

set send_human {.1 .3 1 .05 2}
set prompt ""

################## static variables ####################
set mlpath "/u01/app/oracle/ovm-manager-3/domains/ovm_domain/servers/AdminServer/logs/"
set managerLogs {"AdminServer.log" "CLIAudit.log" "CLI.log" "AdminServer-diagnostic.log"}
set serverLog "/var/log/ovs-agent.log"

## Logging

#######################################################
set adminServer [dict get $configData "adminServer"]
set ovmServerMasterIP [dict get $configData "ovmServerMasterIP"]
set ovmServerSlaveIP [dict get $configData "ovmServerSlaveIP"]

set serverList [list $adminServer $ovmServerMasterIP $ovmServerSlaveIP]
set serverInfo [dict create]

dict set serverInfo $adminServer isManager "True"
dict set serverInfo $ovmServerMasterIP isManager "False"
dict set serverInfo $ovmServerSlaveIP isManager "False"

passwdQuery $serverList serverInfo

foreach server $serverList {
    
    set copyLog $LOGDIR
    append copyLog "Copy_Logs-"
    append copyLog $server
    append copyLog ".log"

    log_user 0
    log_file -a $copyLog
    set success "False"

    set myPassword [dict get $serverInfo $server myPassWD]
    send_user "This is myPassword: $myPassword one space.\n"

    if {[dict get $serverInfo $server isManager] == "True"} {
	send_user "\n\nAttempting to copy Admin and CLI logs from $server...\n"
	foreach log $managerLogs {
	    set mylog $mlpath 
	    append mylog $log
	    set success [copyLog $server $myPassword $mylog $LOGDIR $log]
	    
	    if {$success == "True"} {
		send_verbose "Successfully copied $mylog to $LOGDIR\n"
	    } else {
		send_verbose "Could not copy $mylog to $LOGDIR.  Please view $copyLog for details.\n"
	    }
	}

    } else {

	send_user "\n\nAttempting to copy ovs-agent logs from $server...\n"
	set slog_tmp "$server-ovs-agent.log"
	
	set success [copyLog $server $myPassword $serverLog $LOGDIR $slog_tmp]
	if {$success == "True"} {
	    send_verbose "Successfully copied $serverLog to $LOGDIR$slog_tmp\n"
	} else {
	    send_verbose "Could not copy $serverLog to $LOGDIR.  Please view $copyLog for details.\n"
	}
	
	send_user "\nLogging into $server to run sosreport and multipathd.\n"
	send_user "The commands will be run on the remote server, and then after\n"
	send_user "logging out of the server, the files will be copied over\n"
	send_user "to $LOGDIR\n"
	
	set sosreport "False"
	set multipathd "False"
	set mpdfile "/tmp/$server-multipathd.txt"
	set mpdtmp "$server-multipathd.txt"
    
	set mySpawnID [NodeLogin $server $myPassword]
	set sosreport [runSOS $server $LOGDIR $ticket $mySpawnID]
	sleep 30
	send_user "\n\n"
	set multipathd [runMultipathd $mpdfile $mySpawnID]
	NodeLogout
	
	send_user "Waiting for 30 seconds...\n"
	sleep 30
	
	if {$sosreport == "False"} {
	    send_user "\n\nIssues were encountered while running sosreport on $server,\n"
	    send_user "and therefore it will be necessary to run sosreport and copy it\n"
	    send_user "to $LOGDIR manually.\n"
	} else {
	    set sos_tmp [getFileName $sosreport]
	    if {$sos_tmp == "False"} {
		send_user "\n\nUnable to read sosreport filename, therefore unable to copy\n"
		send_user "the file over.  sosreport was successfully executed on\n"
		send_user "$server, so you can manually copy the file to $LOGDIR."
	    } else {
		set success [copyLog $server $myPassword $sosreport $LOGDIR $sos_tmp]
		if {$success == "True"} {
		    send_verbose "\nSuccessfully copied $sosreport to $LOGDIR\n"
		} else {
		    send_verbose "\nCould not copy $sosreport to $LOGDIR.  Please view $copyLog for details.\n"
		}
	    }
	}
	

	
	send_user "Waiting for two minutes for the copying of the sosreport to actually complete...\n"
	sleep 120
	set success "False"
	
	if {$multipathd == "False"} {
	    send_user "\n\nIssues were encountered while running multipathd on $server,\n"
	    send_user "and therefore it will be necessary to run multipathd and copy the\n"
	    send_user "captured output to $LOGDIR manually.\n"	
	} else {
	    set success [copyLog $server $myPassword $mpdfile $LOGDIR $mpdtmp]
	    if {$success == "True"} {
		send_verbose "\nSuccessfully copied $mpdtmp to $LOGDIR\n"
	    } else {
		send_verbose "\nCould not copy $mpdtmp to $LOGDIR.  Please view $copyLog for details.\n"
	    }
	}
    }    
    
    log_file
}

finishRun 0
    
	
