
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


## It's not necessary to print out all of the 
## info all of the time, but when more detail
## is requested, we can do that...
proc send_verbose {message} {
    global VERBOSE
    
    if {$VERBOSE == "True"} {
	send_user $message
    }
}


## SSH into the manager to begin the CLI session.
proc OVMlogin {} {

    global send_human
    global prompt
    global ovmUser
    global adminServer
    global ovmPassword
    global spawn_id

    set timeout 900

    send_user "\n\nLogging into to the OVM Manager: $adminServer\n"
    spawn ssh -l $ovmUser $adminServer -p 10000
    expect {
	-re ".*Are you sure you want to continue connecting.*?" {
	    send_user "$expect_out(buffer)\nSending yes to the host....\n"; 
	    send -h "yes\r";
	    exp_continue}  
	-re ".*ssh: connect.*" {
	    send_user "$expect_out(buffer)\nUnable to connect to the OVM Manager.\n"
	    send_user "Please check your network connection and try again.\n";
	    finishRun 1}
	"Permission denied, please try again" {
	    send_user "$expect_out(buffer)\nUnable to login to the OVM Manager using the admin password provided.\n"
	    send_user "Please verify that the password is correct and run the script again.\n\n"
	    finishRun 1}
	"password:" {
	    send_user "\nSending password...\n"; 
	    send -h "$ovmPassword\r";
	    exp_continue}
	-re ".*Host key verification failed.*\n" {
	    send_user "$expect_out(buffer)\n";
	    finishRun 1}                 
	-re "(.*)$prompt" {}
	eof {
	    send_user "\nThe ssh session with the OVM Manager has been terminated unexpectedly!"
	    finishRun 1}
    }

    expect "*"

}


## This is used for the GetLogs script, to login
## to the manager or servers as root to obtain
## logfiles.
proc NodeLogin {ServerName PassWD} {
    global send_human

    send_user "\n\nLogging into to $ServerName\n"    
    spawn ssh -l root $ServerName; set mySpawnID $spawn_id
    expect {
	-re ".*Are you sure you want to continue connecting.*?" {
	    send_user "$expect_out(buffer)\nSending yes to the host....\n"; 
	    send -h "yes\r";
	    exp_continue}  
	-re ".*ssh: connect.*" {
	    send_user "$expect_out(buffer)\nUnable to connect to the OVM Manager.\n"
	    send_user "Please check your network connection and try again.\n";
	    finishRun 1}
	-re ".*Permission denied, please try again.*" {
	    send_user "$expect_out(buffer)\nUnable to login to the OVM Manager using the admin password provided.\n"
	    send_user "Please verify that the password is correct and run the script again.\n\n"
	    finishRun 1}
	"password:" {
	    send_user "\nSending password...\n"; 
	    send -h "$PassWD\r";
	    exp_continue}
	-re ".*Host key verification failed.*\n" {
	    send_user "$expect_out(buffer)\n";
	    finishRun 1} 
	-re "(.*)\r" {exp_continue}
    }
    
    expect "*"
    return $mySpawnID

}

proc NodeLogout {} {
    global send_human
    send -h "logout\r"
    return

}

## Capture the output from the CLI commands and print it out.
## If the command fails, sends unexpected output, or times out, 
## this is considered to be an error we can't recover from, so
## we exit.
proc validateCommandOutput {message} {
 
    global logfile
    global successMsg
    global failureMsg
    set timeout 1800

    expect {
        -re "Status: Success" {
	    send_user "$expect_out(buffer)"
	    expect "*"
	    send_user "$expect_out(buffer)\n"
	} 
        -re "Status: Failure" {
	    send_user "$expect_out(buffer)"
	    expect "*"	    
	    send_user "$expect_out(buffer)\n"
	    finishRun 1
	} 
        -re "Received disconnect" {
	    send_user "$expect_out(buffer)\n\nOVM Idle Timeout: The The OVM CLI terminates\n"
	    send_user "idle connections after 15 minutes, and therefore OVM has\n"
	    send_user "terminated the ssh session that was being used for this test.\n\n"
	    send_user "It will be necessary to begin the tests again..\n\n"
            finishRun 1
	}
	timeout {
	    send_user "HCL Watchdog Timeout: The $message failed\n"
            send_user "to complete after more than 30 minutes.  The OVM CLI terminates\n"
	    send_user "idle connections after 30 minutes, therefore the script has been\n"
	    send_user "terminated to prevent further failures with sending commands to\n"
	    send_user "the soon to be terminated SSH session.\n\n"
	    send_user "Please refer to $logfile for additional details.\n\n"
            finishRun 1	    
	}
    }

    expect "*"
}

## Capture the output from the CLI commands, and print it out.
## No verification of success or failure is done in this function.
proc showCommandOutput {message} {

    global logfile
    global successMsg
    global failureMsg
    set timeout 1800
        
    expect {
        -re "Status: Success" {
	    send_user "$expect_out(buffer)"
	    expect "*"
	    send_user "$expect_out(buffer)\n"
	} 
        -re "Status: Failure" {
	    send_user "$expect_out(buffer)"
	    expect "*"	    
	    send_user "$expect_out(buffer)\n"
	} 
        -re "Received disconnect" {
	    send_user "$expect_out(buffer)\n\nOVM Idle Timeout: The The OVM CLI terminates\n"
	    send_user "idle connections after 15 minutes, and therefore OVM has\n"
	    send_user "terminated the ssh session that was being used for this test.\n\n"
	    send_user "It will be necessary to begin the tests again..\n\n"
            finishRun 1
	}
	timeout { 
	    send_user "\nHCL Watchdog Timeout: The $message failed\n"
            send_user "to complete after more than 30 minutes.  The OVM CLI terminates\n"
	    send_user "idle connections after 30 minutes, and therefore the script has\n"
	    send_user "been terminated to avoid further failures.\n\n"
	    send_user "Please refer to $logfile for additional details.\n\n";
            finishRun 1
	}
    }
    
    expect "*"
}

proc parseConfig {configfile} {

    set configData [dict create]

    set fp [open $configfile r]
    set fd [read $fp]
    close $fp
    set data [split $fd "\n"]

    foreach line $data {
	if {$line == ""} {
	    continue
	}     
	switch -regexp -- $line {
	    ^#.* { }
	    .*=.* {
		set pair [split $line =]
		set key [string trim [lindex $pair 0]]           
		set value [string trim [lindex $pair 1]]
		dict set configData $key $value
	    }
	}
    }

    return $configData
}


proc verifyConfigData {protocol configData} {
 
    global requiredParams_NonCHAP
    global requiredParams_CHAP
    global requiredParams_Vendor
    global requiredParams_FC
    global requiredParams_FC_Vendor
    global requiredParams_NFS
    global requiredParams_Cleanup
    global requiredParams_Logs

    set missingParams []

    switch -- $protocol \
	"chap" {
	    set myParams $requiredParams_CHAP
	} "iscsi" {
	    set myParams $requiredParams_NonCHAP
	} "iscsi_vendor" {
	    set myParams $requiredParams_Vendor
	} "fc" {
	    set myParams $requiredParams_FC
	} "fc_vendor" {
	    set myParams $requiredParams_FC_Vendor	    
	} "nfs" {
	    set myParams $requiredParams_NFS
	} "cleanup" {
	    set myParams $requiredParams_Cleanup
	} "logging" {
	    set myParams $requiredParams_Logs
	}

    foreach param $myParams {
	
	if {[dict keys $configData $param] == ""} {
	    lappend missingParams $param
	}
    }

    if {[llength $missingParams] > 0} {
	
	send_user "The following required parameters have not be defined:"
	foreach param $missingParams {
	    send_user "$param\n"
	}
	return "False"
    }

    return "True"
}


proc discoverServers {myServers} {
    upvar 1 $myServers myDict

    global ovmAgentPassword
    global ovmServerMasterIP
    global ovmServerSlaveIP
    global send_human
    global testStep

    send_user "\n## [incr testStep 1].  Discovering the Master Server\n"
    send -h "discoverServer ipAddress=$ovmServerMasterIP password=$ovmAgentPassword takeOwnership=yes\r"
    validateCommandOutput "discoverServer command"
    
    send_user "\n## [incr testStep 1].  Discovering the Secondary Server\n"
    send -h "discoverServer ipAddress=$ovmServerSlaveIP password=$ovmAgentPassword takeOwnership=yes\r"
    validateCommandOutput "discoverServer command"
    
    send_user "\nReading server info...\n"
    
    array set basicServerInfo [getServerIDs]
    set x [array size basicServerInfo]
    set myDict [dict create]
    
    for {set i 0} {$i < $x} {incr i 1} {
	if {[info exists basicServerInfo($i,id)]} {
	    set myTemp [probeServer $basicServerInfo($i,id) $basicServerInfo($i,name)]
	    if {[dict get $myTemp $basicServerInfo($i,name) ip_address] == $ovmServerMasterIP} {
		set masterName $basicServerInfo($i,name)
	    } elseif {[dict get $myTemp $basicServerInfo($i,name) ip_address] == $ovmServerSlaveIP} {
		set slaveName $basicServerInfo($i,name)
	    } else {
		continue
	    }
	    
	    set myDict [dict merge $myTemp $myDict]
	    unset myTemp
	}
    }

    expect "*"
    return [list $masterName $slaveName]
}


### Given a server name and ID, gather all the relevant 
### information that will be needed to execute the
### tests. The information is returned to the calling
### program in a dictionary.
proc probeServer {serverID serverName} {

    global send_human
    global failureMsg
    global prompt

    match_max 20000
    set expect_out(buffer) {}

    set ethPorts {}
    set bondPorts {}
    set fsPlugins {}
    set saPlugins {}
    set diskList {}
    set iscsi []
    set fc []

    # Grab the output, and then we'll parse it afterwards.
    send_verbose "Gathering information from Server ID: $serverID\n"
    send -h "show server id=$serverID\r"
    sleep 5
    expect {
        -re "Status: Failure" {
	    send_user "$expect_out(buffer)"
	    expect "*"	    
	    send_user "$expect_out(buffer)\n"
	    finishRun 1
	} 
	-re "(.*)$prompt" {
	    set myString $expect_out(buffer)
	}
	timeout {finishRun 1}
    }
    
    ## Strip the '[' and ']' characters from the string
    ## because they make it hard to parse.
    set myString [string map {\[ __} $myString]
    set myString [string map {\] __} $myString]

    set mylists {"ipMatches" 
	"ethMatches" 
	"bondMatches" 
	"fspluginMatches" 
	"sapluginMatches" 
	"pdMatches" 
	"iscsiMatches" 
	"fcMatches"}

    ## regexp returns the string that was matched, plus the groupings.
    ## In this case we can expect that for every match (exluding
    ## IP Address), there will be three strings to with relevant
    ## information: the matched string, the id, and the name.
    set ipMatches [regexp -all -inline -linestop "Ip Address = (\[0-9\.]*)" $myString]
    set ethMatches [regexp -all -inline -linestop "Ethernet Port \[0-9]+ = (.*?) __(.*?) on \[^\n]*__" $myString]
    set bondMatches [regexp -all -inline -linestop "Bond Port \[0-9]+ = (.*?) __(.*?) on \[^\n]*__" $myString]
    set fspluginMatches [regexp -all -inline -linestop "FileServer Plugin \[0-9]+ = (.*?) __(\[^\n]*)__" $myString]
    set sapluginMatches [regexp -all -inline -linestop "StorageArray Plugin \[0-9]+ = (.*?) __(\[^\n]*)__" $myString]
    set pdMatches [regexp -all -inline -linestop "Physical Disk \[0-9]+ = (.*?) __(\[^\n]*)__" $myString]
    set iscsiMatches [regexp -all -inline -linestop "Storage Initiator \[0-9]+ = (iqn.*?) __\[^\n]*__" $myString]
    set fcMatches [regexp -all -inline -linestop "Storage Initiator \[0-9]+ = (0x.+?) __\[^\n]*__" $myString]

    ## Begin adding the information to the dictionary
    dict set myServer $serverName server_name $serverName
    dict set myServer $serverName server_id $serverID

    foreach matchlist $mylists {		   

	switch -- $matchlist \
	    "ipMatches" {
		dict set myServer $serverName ip_address [lindex $ipMatches 1]
	    } "ethMatches" {
		foreach {group0 group1 group2} $ethMatches {
		    send_verbose "Found this Ethernet Port: $group2\n"
		    lappend ethPorts $group2 [string trim $group1]
		}
		dict set myServer $serverName eth_ports $ethPorts
	    } "bondMatches" {
		foreach {group0 group1 group2} $bondMatches {
		    send_verbose "Found this Ethernet Port: $group2\n"
		    lappend bondPorts $group2 [string trim $group1]
		}
		dict set myServer $serverName bond_ports $bondPorts
	    } "fspluginMatches" {
		foreach {group0 group1 group2} $fspluginMatches {
		    send_verbose "Found this FileServer Plugin: $group2\n"
		    lappend fsPlugins [string map {/ //} $group2] [string trim $group1]
		}
		dict set myServer $serverName fs_plugins $fsPlugins
	    } "sapluginMatches" {
		foreach {group0 group1 group2} $sapluginMatches {
		    send_verbose "Found this StorageArray Plugin: $group2\n"
		    lappend saPlugins [string map {/ //} $group2] [string trim $group1]
		}
		dict set myServer $serverName sa_plugins $saPlugins
	    } "pdMatches" {
		foreach {group0 group1 group2} $pdMatches {
		    send_verbose "Found this PhysicalDisk: $group2\n"
		    lappend diskList [string trim $group1]
		}
		dict set myServer $serverName phys_disks $diskList
	    } "iscsiMatches" {
		foreach {group0 group1} $iscsiMatches {
		    send_verbose "Found this iSCSI initiator: $group1\n"
		    lappend iscsi [string trim $group1]
		} 
		dict set myServer $serverName iscsi $iscsi
	    } "fcMatches" {
		foreach {group0 group1} $fcMatches {
		    send_verbose "Found this FibreChannel initiator: $group1\n"
		    lappend fc [string trim $group1]
		}
		dict set myServer $serverName fc $fc
	    }
    }

    match_max 2000
    expect "*"
    return $myServer

}

proc printTestHeader {testcase output} {
    send_user "\n--------------------------------------------------------------------------\n"
    send_user "$testcase: $output"
    send_user "\n--------------------------------------------------------------------------\n"
}


proc refreshLUNs {is_iscsi lunList serverNames myServers} {
    global SAN_ServerName

    if {$is_iscsi == "True"} {
	
	foreach server $serverNames {
	    
	    set myID [dict get $myServers $server server_id]
	    
	    send_user "\n## [incr testStep 1]. Rescanning the Physical Disks on $server...\n"
	    send -h "refreshStorageLayer Server id=$myID\r"
	    validateCommandOutput "refreshStorageLayer command for $server"
	    
	    send_user "Waiting 120 seconds for changes to be propagated to the manager...\n"
	    sleep 120
	} 
	
    } else {
	
	if {[llength $lunList] == 0} {

	    foreach server $serverNames {

		set myID [dict get $myServers $server server_id]
    
		send_user "\n## [incr testStep 1]. Rescanning the Physical Disks on $server...\n"
		send -h "refreshStorageLayer Server id=$myID\r"
		validateCommandOutput "refreshStorageLayer command for $server"
		
		send_user "Waiting 120 seconds for changes to be propagated to the manager...\n"
		sleep 120

		set newMaps []
		set origDisk [dict get $myServers $server phys_disks]
		set mappedDisks [getDisks $server $myID]
		
		# Verify that the newly mapped disk list is larger than
		# the list of disks found when the servers were discovered.
		if {[llength $origDisk] >= [llength $mappedDisks]} {
		    send_user "FAILURE: No new LUNs were found on $server!\n"
		    finishRun 1
		}

		foreach lun $mappedDisks {
		    if {[lsearch -exact $origDisk $lun] == -1} {
			lappend newMaps $lun
			if {[lsearch -exact $lunList $lun] == -1} {
			    lappend lunList $lun
			    dict set lunInfo $lun is_shared "False"
			} else {
			    dict set lunInfo $lun is_shared "True"
			    incr shared 1
			}
		    }
		}

		unset newMaps
		unset origDisk
		unset mappedDisks
	    }
	}

	foreach lun $lunList {
	    send_user "\n## [incr testStep 1]. Refreshing the PhysicalDisk: $lun\n"
	    send -h "refresh PhysicalDisk id=$lun\r"
	    validateCommandOutput "refresh physicaldisk command"
	    
	    send_user "Waiting 30 seconds for changes to be propagated to the manager...\n"
	    sleep 30
	}
    }
}


## Given a server, and then a list containing information
## about it; find all the Physical Disks associated with 
## that server.
proc getDisks {server_name server_id} {
    global testStep
    global send_human
    global failureMsg
    global prompt

    set diskList {}
    set timeout 600
 
    send_user "\n## [incr testStep 1]. Finding LUNs mapped to $server_name...\n"
    send -h "show server id=$server_id\r"
    sleep 5
    expect {
        -re "Status: Failure" {
	    send_user "$expect_out(buffer)"
	    expect "*"	    
	    send_user "$expect_out(buffer)\n"
	    finishRun 1
	} 
	-re "(.*)$prompt" {
	    set myString $expect_out(buffer)
	}
	timeout {finishRun 1}
    }
    
    ## Strip the '[' and ']' characters from the string
    ## because they make it hard to parse.
    set myString [string map {\[ __} $myString]
    set myString [string map {\] __} $myString]

    set pdMatches [regexp -all -inline -linestop "Physical Disk \[0-9]+ = (.*?) __(\[^\n]*)__" $myString]
    foreach {group0 group1 group2} $pdMatches {
	send_verbose "Found this PhysicalDisk: $group2 with this id: $group1 .\n"
	lappend diskList [string trim $group1]
    }
    
    return $diskList
}

## Given a Physical Disk name, and a Server ID, verify
## that the disk is mapped to the server.
proc verifyDiskMapping {diskname server} {

    global failureMsg
    global send_human
    global testStep

    set timeout 900
    set present "False"
    set diskList []

    send_verbose "\n## [incr testStep 1]. Verifying the presence or absence of $diskname on $server...\n"
    send -h "show server name=$server\r"
    sleep 4
    expect {
        -re "Status: Failure" {
	    send_user "$expect_out(buffer)"
	    expect "*"	    
	    send_user "$expect_out(buffer)\n"
	    finishRun 1
	} 
	-re "Physical Disk .*? = .*?  .(\[A-Za-z0-9\_\-]*).\n\r" {
	    lappend diskList $expect_out(1,string)
	    send_verbose "Found this disk: $expect_out(1,string)\n"
	    exp_continue}
	-re ".*?OVM> " {}
	timeout {
	    send_user "Encountered unexpected error or output while verifying disk presence\n" 
	    finishRun 1}
    }

    if {[lsearch $diskList $diskname] >= 0} {
	set present "True" 
    }

    return $present
}

## With the generic plugin, the CLI doesn't update the disk list
## in the same way as when a vendor plugin is used.  LUNs
## that have been unmapped are still displayed in the disk
## list, and the only way to really know that the LUN
## is no longer mapped is to look at the events for the 
## LUN in question.
proc verifyDiskMapGeneric {diskname} {

    global failureMsg
    global send_human
    global testStep
    global prompt

    set timeout 900
    set present "False"  

    ## We need to look at the latest event for the LUN in question.
    ## The event list doesn't always display events in order, so
    ## we have to make some assumptions about how to gather the 
    ## information.  For the case of the UNMAPPED lun, we know that
    ## the test cases never involve re-mapping a LUN that has been
    ## unmapped -- infact, unmapped LUNs are always deleted to avoid
    ## confusion with them.  This means that we can check to see
    ## if a LUN is in a WARNING state, meaning that it's either offline
    ## or unmapped.
    send_user "\n## [incr testStep 1]. Verifying the status of disk: $diskname\n"
    send -h "getEvents objType=PhysicalDisk objID=$diskname severity=WARNING\r"
    sleep 4
    expect {
        -re "Status: Failure" {
	    send_user "$expect_out(buffer)"
	    expect "*"	    
	    send_user "$expect_out(buffer)\n"
	    finishRun 1
	} 
	-re ".*?type:storage.device.off.path.*?\n\r" {
	    send_user "Disk is offline or missing\n"
	    set present "Unmapped"
	}
	-re ".*?type = storage.device.off.path.*?\n\r" {
	    send_user "Disk is offline or missing\n"
	    set present "Unmapped"
	}
	-re ".*$prompt" {}
    }

    expect "*"

    if {$present == "Unmapped"} {
	return $present
    }

    ## If we haven't found a WARNING event, check to see 
    ## if the LUN is in other possible online event states.
    send -h "getEvents objType=PhysicalDisk objID=$diskname amount=1\r"
    sleep 4
    expect {
        -re "Status: Failure" {
	    send_user "$expect_out(buffer)"
	    expect "*"	    
	    send_user "$expect_out(buffer)\n"
	    finishRun 1
	} 
	-re ".*?type = storage.device.online.*?\n\r" {
	    send_user "Disk is online and present!\n";
	    set present "Mapped"
	}
	-re ".*?type = lifecycle.create.*?\n\r" {
	    send_user "Disk was just mapped for the first time!\n"
	    set present "Created"
	}
	-re ".*?type = lifecycle.modify.*?\n\r" {
	    send_user "Disk is online and present!\n"
	    set present "Modified"
	}

	-re ".*$prompt" {}
    }
    
    expect "*"
    return $present
    
}

### For OVM3.3 there is no straight forward way to create a Repository
### with a FC or iSCSI LUN using the CLI.  We need use the OVS 
### server as a local fileserver then create a filesystem on the LUN, 
### using the OVS server, then once that's done you can use the FS 
### you just created for the repository.  It is no longer possible 
### to just give the CLI a LUN ID to create the repository.  
### See OVM bug #16971014.  This won't be fixed.
proc createRepositoryOnSAN  {myLocalFileServer fs_name lunID repoName} {

    global failureMsg
    global send_human
    global testStep
    global prompt

    expect "*"
    set fsID "False"
    set repoID "False"
    set myMatch ""
    set output ""

    ## Create the FileSystem on the LUN we want to use for 
    ## the Repository
    send_user "\n## [incr testStep 1]. Creating the OCFS2 Filesystem for the Repository.\n"
    send -h "create FileSystem name=$fs_name physicalDisk=$lunID on FileServer id=$myLocalFileServer\r"
    sleep 8
    expect {
	$failureMsg {
	    send_user "$expect_out(buffer)"
	    expect "*"
	    send_user "$expect_out(buffer)\n\n"
	    send_user "Fatal Failure while attempting create a filesystem on LUN $lunID.\nTerminating!\n"
	    finishRun 1
	}
	-re ".*$prompt" {
	    set output $expect_out(buffer) 
	}
    }

    set myMatch [regexp -inline -linestop "id:(.+?) name:.+?" $output]

    foreach {group0 group1} $myMatch {
	send_user "$output\n"
	send_user "Successfully created the OCFS2 FileSystem: $group1.\n"
	set fsID $group1
    }

    if {$fsID == "False"} {
	send_user "Unable to find the FileSystem ID for the filesystem which was just created!"
	finishRun 1
    } else {
	set fsID [string trim $fsID]
    }

    expect "*"
    set output ""
    set myMatch ""
    sleep 3
    
    ## Finally, create the repository on the newly created FileSystem on the 
    ## LUN we were planning to use....
    send_user "\n## [incr testStep 1]. Creating the Repository: $repoName.\n"
    send -h "create Repository name=$repoName on FileSystem id=$fsID\r"
    sleep 8
    expect {
        -re "Status: Failure" {
	    send_user "$expect_out(buffer)"
	    expect "*"	    
	    send_user "$expect_out(buffer)\n"
	    send_user "Fatal Failure while attempting create a Repository on FileSystem $fs_name.\nTerminating!\n"
	    finishRun 1
	} 
	-re ".*$prompt" {
	    set output $expect_out(buffer)
	}
    }

    set myMatch [regexp -inline -linestop "id:(.+?) name:.+?" $output]

    foreach {group0 group1} $myMatch {
	send_user "$output\n"
	send_user "Successfully created the Repository $repoName on $fsID.\n"
	set repoID $group1
    }

    if {$repoID == "False"} {
	send_user "Unable to find the FileSystem ID for the filesystem which was just created!"
	finishRun 1
    } 

    expect "*"
    return [string trim $repoID]
}

proc findLocalFileServer {masterName} {

    global failureMsg
    global send_human
    global testStep
    global prompt
    
    set myLocalFileServer "False"
    set myMatch ""
    set output ""

    expect "*"

    ## Find the local FileServer on the OVS Server
    send_user "\n## [incr testStep 1]. Finding a local FileServer on which to create OCFS2 FileSystems\n"
    send -h "list FileServer\r"
    sleep 8
    expect {
        -re "Status: Failure" {
	    send_user "$expect_out(buffer)"
	    expect "*"	    
	    send_user "$expect_out(buffer)\n"
	    send_user "Fatal Failure while attempting to list FileServers.\nTerminating!\n"
	    finishRun 1
	} 
	-re ".*$prompt" {
	    set output $expect_out(buffer)
	}
    }

    set myMatch [regexp -inline -linestop "id:(.+?) name:Local FS $masterName" $output]

    foreach {group0 group1} $myMatch {
	send_user "$output\n"
	send_user "Found this local FileServer on $masterName: $group1.\n"
	set myLocalFileServer $group1
    }
    

    if {$myLocalFileServer == "False"} {
	send_user "output\n"
	send_user "Unable to find the FileSystem ID for the filesystem which was just created!"
	finishRun 1
    } 

    expect "*"
    return $myLocalFileServer
}


proc importInstallMedia {repoName myURL type} {
    global failureMsg
    global send_human
    global testStep
    global prompt
 
    switch -- $type \
	"template" {
	    send  -h "importTemplate repository name=$repoName url=$myURL\r"
	} "assembly" {
	    send -h "importAssembly repository name=$repoName url=$myURL\r"
	} "iso" {
	    send -h "importVirtualCdrom repository name=$repoName url=$myURL\r"
	}
    expect {
        -re "Status: Failure" {
	    send_user "$expect_out(buffer)"
	    expect "*"	    
	    send_user "$expect_out(buffer)\n"
	    send_user "Fatal Failure while attempting to import $myURL.\nTerminating!\n"
	    finishRun 1
	} 
	-re "id:(.*?) name:.*?\n\r" {
	    set myID [string trim $expect_out(1,string)]
	}
	-re ".*$prompt" {
	    send_user "$expect_out(buffer)"
	    send_user "Didn't find a matching $type ID!\n"
	    return "False"
	}
    }

    expect "*"
    return $myID
}

proc findAssemblyVMID {assemblyID} {

    global failureMsg
    global send_human
    global testStep
    global prompt

    expect "*"

    send -h "list AssemblyVm\r"
    sleep 5
    expect {
        -re "Status: Failure" {
	    send_user "$expect_out(buffer)"
	    expect "*"	    
	    send_user "$expect_out(buffer)\n"
	    send_user "Fatal Failure while attempting to determine the AssemblyVM Name.\nTerminating!\n"
	    finishRun 1
	} 
	-re "id:($assemblyID.*?) name:.*?\n\r" {
	    send_user "Found the AssemblyVM id: $expect_out(1,string)\n"
	    set myID [string trim $expect_out(1,string)]
	}
	-re ".*$prompt" {
	    send_user "$expect_out(buffer)\n\n"
	    send_user "Didn't find a matching AssemblyVM ID!\n"
	    return "False"
	}
    }
    
    expect "*"
    return $myID
}


proc createVMFromAssembly {assemblyVMID} {
    global failureMsg
    global send_human
    global testStep
    global prompt

    expect "*"

    send -h "createVmFromAssembly AssemblyVm id=$assemblyVMID\r"
    sleep 4
    expect {
        -re "Status: Failure" {
	    send_user "$expect_out(buffer)"
	    expect "*"	    
	    send_user "$expect_out(buffer)\n"
	    send_user "Fatal Failure while attempting to create the VM from the Assembly.\nTerminating!\n"
	    finishRun 1
	} 
	-re "id:(.*?) name:.+?\n\r" {
	    send_user "Found the new VM id: $expect_out(1,string)\n"
	    set myID [string trim $expect_out(1,string)]
	}
	-re ".*$prompt" {
	    send_user "$expect_out(buffer)"
	    send_user "Didn't find the ID for the newly created VM??!\n"
	    return "False"
	}
    }

    expect "*"
    return $myID
}


proc setupNetworks {serverNames myServers storage} {

    global testStep
    global VM_Netmask 
    global VM_Network 
    global VM_NetworkPort 
    global storageNetworkNetmask 
    global storageNetworkIP 
    global storageNetworkPort

    foreach server $serverNames {

	set myEthPorts [dict get $myServers $server eth_ports]
	set myBondPorts [dict get $myServers $server bond_ports]
	set allNetworkPorts [list {*}$myEthPorts {*}$myBondPorts]

	send_user "\n## [incr testStep 1]. Verifying network configuration on "
	send_user "$server for the VM Network: $VM_Network\n"
	if {[addPortToNetwork $VM_Netmask $VM_Network $VM_NetworkPort $allNetworkPorts] != "True"} {
	    finishRun 1
	}
	
	if {$storage == "True"} {
	    send_user "\n## [incr testStep 1]. Verifying network configuration on "
	    send_user "$server for the Storage Network: $storageNetworkIP\n"
	    if {[addPortToNetwork $storageNetworkNetmask $storageNetworkIP $storageNetworkPort $allNetworkPorts] != "True"} {
		finishRun 1
	    }
	}
		
	unset myEthPorts
	unset myBondPorts
	unset allNetworkPorts
	
    }
}



## When we're verifying disks, we need to be able
## to differentiate between a localdisk, which we 
## don't care about, and a mapped LUN, which we do 
## care about.
proc isLocalDisk {diskname} {

    global failureMsg
    global send_human
    global prompt

    set timeout 300
    set isLocal "False"

    send -h "show physicaldisk id=$diskname\r"
    sleep 8
    expect {
        -re "Status: Failure" {
	    send_user "$expect_out(buffer)"
	    expect "*"	    
	    send_user "$expect_out(buffer)\n"
	    send_user "Fatal Failure while attempting to view the PhysicalDisk $diskname.\nTerminating!\n"
	    finishRun 1
	} 
	-re "VolumeGroup = Local_Storage_Volume_Group.*?\n\r" {
	    set isLocal "True"
	}
	-re ".*$prompt" {}
	timeout {
	    send_user "Watchdog timeout while verifying local disk.\nExiting!\n"
	    finishRun 1
	}
    }

    expect "*"
    return $isLocal
}


proc verifyExpectedMaps {disklist expectedMap expectedUnmap sizelist} {

    set status "False"
    set unmap 0
    set map 0
    set sizes "True"

    foreach disk $disklist {
	
	if {[isLocalDisk $disk] == "True"} {
	    incr map 1
	    send_user "Why did we get a local disk????\n"
	    continue
	}
	
	set status [verifyDiskMapGeneric $disk]

	switch -- $status \
	    "Unmapped" {
		set unmap [incr unmap 1]
	    } "Mapped" {
		set map [incr map 1]
	    } "Created" {
		set map [incr map 1]
	    } "Modified" {
		set map [incr map 1]
	    } default {
		send_user "\n\n\nUnknown disk status encountered. Unable to procede.\nTerminating.\n"
		send_user "This is the stupid status: $status  WTF!?!?!?!????\n\n\n" 
		##### FIXME: DON'T EXIT HERE!!!!!!!!!!!!
	    }

	set mySize [getDiskSize $disk]
	set index [lsearch $sizelist $mySize]

	if {$index == -1} {
	    send_user "Unexpected LUN size!  Was expecting to find a "
	    printSizeList $sizelist 
	    send_user "LUN,\nand found a $mySize"
	    send_user "GB LUN instead.  Terminating.\n\n"
	    return "False"
	} else {
	    # remove the size we just found from the size list
	    # so that we don't accidentally get two luns of the
	    # same size.
	    set sizelist [lreplace $sizelist $index $index]
	}
    }

    if {$unmap != $expectedUnmap || $map != $expectedMap} {
	send_user "Expected $expectedMap LUNs to be mapped, and found $map.\n"
	send_user "Expected $expectedUnmap LUNs in the offline or warning state, and found $unmap.\n"
	send_user "LUNs are not mapped in accordance with expectations.\nTerminating.\n"
	return "False"
    } else {
	return "True"
    }
}

proc printSizeList {mylist} {

    set myLength [llength $mylist]
    set count 0

    if {$myLength == 0} {
	return
    } elseif {$myLength == 1} {
	send_user [lindex $mylist 0]
	send_user "GB "
    } else {
	set actual [expr $myLength - 1]
	while {$count < $actual} {
	    send_user [lindex $mylist $count]
	    send_user "GB, "
	    incr count 1
	}
	send_user "or "
	send_user [lindex $mylist $count]
	send_user "GB "
    }


}


proc getDiskSize {diskid} {

    global failureMsg
    global send_human
    global testStep
    global prompt

    set mySize 0

    send_user "\n## [incr testStep 1]. Reading disk size information for disk id=$diskid\n"
    send -h "show physicaldisk id=$diskid\r"
    sleep 5
    expect {
        -re "Status: Failure" {
	    send_user "$expect_out(buffer)"
	    expect "*"	    
	    send_user "$expect_out(buffer)\n"
	    send_user "Fatal Failure while attempting to view the PhysicalDisk $diskid.\nTerminating!\n"
	    finishRun 1
	} 
	-re "Size .*? = (.*?)\n\r" {
	    set mySize $expect_out(1,string)
	    exp_continue
	}
	-re ".*$prompt" {}
    }
    expect "*"

    ## The disk size is reported occasionally as a double, instead of int.
    ## but we have no way to tell the difference between a disk that is
    ## 5G and one that is 5.0G, but the tests looking at size will fail
    ## if the size reported as 5.0 when we're looking for 5, so eliminate 
    ## that failure by stripping the extraneous numbers after the decimal 
    ## point.  If the size doesn't match, it doesn't match, but decimals 
    ## shouldn't cause the test to fail
    set drop [string first "." $mySize]

    if {$drop == -1} {
	return  $mySize
    } else {
	return [string trimright [string range $mySize 0 $drop] "."]
    }
}


## The CLI keeps all LUNs (both mapped and unmapped) in the disklist
## so in order to keep track of the disks that are expected to be
## associated with each server, we need to keep the disk list clean.
## This function should only be called after having explicitly 
## unmapped LUNs.
proc deleteLUNs {lunList lunInfo} {
    upvar 1 $lunList disklist
    upvar 1 $lunInfo myDict

    global testStep
    set dcount 0

    foreach disk $disklist {
	
	if {[verifyDiskMapGeneric $disk] == "Unmapped"} {
	    send_verbose "Found an unmapped LUN.\n"
	    send_user "\n## [incr testStep 1]. Deleting the unmapped LUN.\n"
	    send -h "delete PhysicalDisk id=$disk\r"
	    validateCommandOutput "delete PhysicalDisk command"

	    # Remove the LUN from the dictionary and our tracking list
	    dict unset $myDict $disk
	    set index [lsearch $disklist $disk]
	    set disklist [lreplace $disklist $index $index]

	    # keep track of the number of luns we're deleting, we
	    # check this later
	    incr dcount 1
	}
    }

    return $dcount
}

## Attempt to resize (grow and shrink) Physical Disks, using the new disk
## passed in to the function.  This function returns true if the the
## resize was successful.
proc resizeDisks {diskname newsize} {

    global testStep
    global send_human
    global successMsg
    global failureMsg
    global prompt
    
    set timeout 600
    set resize "True"
    
    send_user "\n## [incr testStep 1]. Resizing LUN $diskname, setting new size at $newsize GB\n"
    send -h "edit physicaldisk name=$diskname size=$newsize\r"

    sleep 5
    
    expect {
	$successMsg {
	    send_user "$expect_out(buffer)";
	    expect "*"
	    send_user "$expect_out(buffer)\n"
	    set resize "True"
	} 
	$failureMsg {
	    send_user "$expect_out(buffer)";
	    expect "*"
	    send_user "$expect_out(buffer)\n"
	    set resize "False"; 
	}
	-re "(.*)$prompt" {}
	timeout { 
	    send_user "OVMM Response Timeout: An unexpected error has occurred while executing the disk resize:\n"
	    send_user "Please refer to $logfile for additional details.\n\n";
	    set resize "Unknown"}
    }

    expect "*"
    return $resize
}


## Given an IP address (or subnet), and a Network Role,
## create a new network.  If the network has already been 
## defined, this function will attempt to add the new Role 
## to the existing network.
proc createNetwork {myIP myRole} {

    global testStep
    global send_human
    global failureMsg
    global prompt

    set timeout 600
    set myNetworks []

    send -h "list network\r"
    sleep 4
    expect {
	$failureMsg {
	    send_user "$expect_out(buffer)";
	    expect "*"
	    send_user "$expect_out(buffer)\n"
	    finishRun 1}
	-re "id:.*? name:(.*?)\n\r" {
	    send_verbose "Found this network: $expect_out(1,string)\n"
	    lappend myNetworks $expect_out(1,string); 
	    exp_continue}
	-re "(.*)$prompt" {}
	timeout {
	    send_user "An unexpected error occurred while reading Network information.\n"
	    finishRun 1}
    }


    if { [lsearch $myNetworks $myIP] >= 0} {
	send_verbose "\nFound an existing Network named $myIP;\n"
	send_verbose "Attempting to update $myIP with role=$myRole.\n"
	updateNetworkRoles $myIP $myRole
    } else {
	send_user "\n## [incr testStep 1]. Creating the $myRole network: $myIP\n" 
	send -h "create network name='$myIP' roles=$myRole\r"
	sleep 3
	validateCommandOutput "create network command"
    }
    
}

## Update an existing Network with additional Roles.
proc updateNetworkRoles {paramIP paramRole} {

    global testStep 
    global failureMsg
    global send_human
    global prompt

    set timeout 600
    set myRoles []
    set roles ""
    set alreadySet 0
    
    send_verbose "Gathering information about existing Roles for Network: $paramIP\n"
    send -h "show network name=$paramIP\r"
    sleep 4
    expect {
	$failureMsg {
	    send_user "$expect_out(buffer)";
	    expect "*"
	    send_user "$expect_out(buffer)\n"
	    finishRun 1}
	-re "Role \[0-9] = (.*?)\n\r" {
	    switch -- $expect_out(1,string) \
		"Management" {
		    lappend myRoles "MANAGEMENT"
		} "Live_Migrate" {
		    lappend myRoles "LIVE_MIGRATE"
		} "Cluster_Heartbeat" {
		    lappend myRoles "CLUSTER_HEARTBEAT"
		} "Virtual_Machine" {
		    lappend myRoles "VIRTUAL_MACHINE"
		} "Storage" {
		    lappend myRoles "STORAGE"
		} default {
		    send_user "Unknown network role encountered... exiting\n"
		}
	    exp_continue}
	-re "(.*)$prompt" {}
	timeout {
	    send_user "An unexpected error occurred while viewing $paramIP\n"
	    finishRun 1}
    }

    ## Verify that the role hasn't already been assigned to this network
    ## and if not, set it.
    if {[lsearch $myRoles $paramRole] == -1} {
	send_user "\n## [incr testStep 1]. Adding the role $paramRole to the $paramIP network...\n"
	lappend myRoles $paramRole
	set newRoles [join $myRoles ","] 
	send -h "edit network name=$paramIP roles=$newRoles\r"
	validateCommandOutput "edit network command"
    } else {
	send_verbose "The role $paramRole was already set for the $paramIP network\n"
    }

}

proc addPortToNetwork {netmask network portName portList} {

    global testStep
    global send_human
    global failureMsg
    global prompt

    array set myPorts $portList
    set existingPorts []
    set timeout 600
    send_verbose "Gathering port information for Network: $network...\n"
    send -h "show network name=$network\r"

    sleep 5

    expect { 
	$failureMsg {
	    send_user "$expect_out(buffer)";
	    expect "*"
	    send_user "$expect_out(buffer)\n"
	    finishRun 1}
	-re "Port \[0-9]*? = (\[0-9a-f]*?) (.*?)\n\r" {
	    send_verbose "Found existing port $expect_out(1,string) = $expect_out(2,string)\n"
	    lappend existingPorts [string trim $expect_out(1,string)]
	    exp_continue}
	-re "(.*)$prompt" {}
	timeout {
	    send_user "An unexpected error has occurred while reading reading $network Network information.\n"
	    finishRun 1}
    }


    # compare the ports already configured on the network
    # the list of ports known on the server.  If we find
    # a match, a port has already been configured on this
    # network, so there's nothing left to do.
    set match "False"

    foreach port $existingPorts {
	if {[lsearch -exact $portList $port] >= 0} {
	    set match "True"
	    break
	}
    }

    if {$match == "True"} {
	send_verbose "A port has already been configured on the $network network.  Continuing...\n"
	return "True"
    }

    # Else, no ports have been configured, so we will configure
    # the port specified by the user.
    send_user "\n## [incr testStep 1]. Updating the $network network to use $portName.\n"
    send -h "add port id=$myPorts($portName) to network name=$network\r"
    validateCommandOutput "update storage network command"

    return "True"
}


## Given a list of vnic IDs, add each to the
## network.  If the vnic is already associated
## with the network, this is essentially a NOP.
proc addVNICtoNetwork {network} {

    global testStep
    global send_human
    global failureMsg
    global prompt

    array set myVNICs [getList vnic]

    foreach key [array names myVNICs] {
	send_user "\n## [incr testStep 1]. Adding the vNIC to the $network network\n"
	send -h "add Vnic id=$myVNICs($key) to Network name=$network\r"	
	validateCommandOutput "add Vnic to Network command"
    }

    return "True"
}


## Assumes vnics have already been created and added to 
## the network.....
proc getAvailableVNIC {} {

    global send_human
    global prompt
    
    set timeout 300
    set found "False"
    array set myVNICs [getList vnic]

    foreach key [array names myVNICs] {	
	send -h "show vnic id=$myVNICs($key)\r"
	expect {
	    -re "Vm Id = .+?" { 
		set found "True"; 
		exp_continue
	    }
	    -re "(.*)$prompt" {}
	}

	if {$found == "False"} {
	    send_verbose "Found this available vnic: $key\n"
	    return $myVNICs($key)
	} else {
	    set found "False"
	}
    }

    return "False"
}


## We only want to add vNICs to VMs if they
## haven't been added automatically, to avoid
## issues that stem from having multiple
## live nics on the vm. 
proc addVnic {vnic vmname} {

    global send_human
    global prompt
    
    set timeout 300
    set found "False"

    send -h "show vm name=$vmname\r"
    sleep 3
    expect {
	-re "Status: Failure" {
	    send_user "$expect_out(buffer)";
	    expect "*"
	    send_user "$expect_out(buffer)\n"
	    finishRun 1
	}
	-re "Vnic \[0-9]* = (.*?) \\\[(.*?)]\n\r" {
	    send_user "Found this vnic: $expect_out(2,string) on $vmname.  Skipping.\n"
	    set found "True"
	}
	-re "(.*)$prompt" {}
	timeout {send_user "Timeout occurred while attempting to view vNICs on $vmname!\n"; finishRun 1}
    }
    
    expect "*"
    
    if {$found == "False"} {
	send -h "add vnic id=$vnic to vm name=$vmname\r"
	validateCommandOutput "add vnic command"
    }
    
}


#### This one is used by the new Generic tests
#### And find_SCSI_Plugins is used by the old
#### vendor plugin tests.  Pick one and get rid
#### of the other.  They're both exactly the same.
#### Not sure what I was thinking....
proc findPlugin {askUser type} {

    global testStep
    global send_human
    global prompt

    set pluginNameList []
    set pluginIDList []

    set allplugins ""    
    set myPlugin ""
    set mismatch "True"
    set timeout 900
    set andthis ""


    send_user "\nGathering the list of installed Storage Connect Plugins...\n"

    if {$type == "SCSI"} {
	send -h "list StorageArrayPlugin\r"
    } else {
	send -h "list FileServerPlugin\r"
    }
    sleep 5
    expect {
	-re "id:(.*?) name:(.*?)\n\r" {
	    send_verbose "Found this plugin: $expect_out(2,string)\n"
	    lappend pluginNameList $expect_out(2,string)
	    lappend pluginIDList [string trim $expect_out(1,string)]
	    exp_continue}
	-re "(.*)$prompt" {set output $expect_out(buffer)}
    	timeout {
	    send_user "Timeout received from OVM while attempting to view installed plugin data.\n"
	    send_user "Terminating.\n"
	    finishRun 1
	}
    }
    
    ## If this is true, we're using a vendor supplied plugin
    ## so we want to ask the user which plugin to use.
    ## If it's not set, then we know we're just doing the
    ## generic plugin tests, and we'll just look for the 
    ## name of the generic plugin.
    if {$askUser == "True"} {
	set index 0
	set myVal ""
	set myPrompt "This is the complete list of Storage Connect plugins found by OVM.\n"

	foreach plugin $pluginNameList {   
	    append myPrompt "$index. $plugin\n"
	    incr index 1
	}

	append myPrompt "Please enter the number corresponding to the plugin\n"
	append myPrompt "name to be used in today's certification tests: "
	
	while {$mismatch == "True"} {
	    send_user "\n\n$myPrompt"
	    expect_user {
		-re "(\[0-9]+)\n" {
		    set userinput $expect_out(1,string);
		    set mismatch "False"
		}
		-re "(.*)\n" {
		    send_user "You entered an invalid choice.\n"
		}
		timeout {
		    send_error "The script has timed out after waiting 30 minutes for user input.\n"
		    send_error "Terminating.\n"
		    finishRun 1
		}
	    }
	}
	set myPlugin [lindex $pluginIDList $userinput]
	send_user "This is myPlugin ID: $myPlugin\n"
    } else {
	foreach plugin $pluginNameList { 
	    send_user "This is my plugin name: $plugin\n"
	    if {[string match *eneric* $plugin]} {
		#set myPlugin $plugin
		set pindex [lsearch $pluginNameList $plugin]
		break
	    }
	}
	set myPlugin [lindex $pluginIDList $pindex]
	send_user "This is myPlugin ID: $myPlugin\n"
    }
    
    return $myPlugin
}


## Since it's hard to determine exactly how OVMM will display 
## the plugin name, we want to make sure we're always using 
## the name that is expected to avoid script failures.  
## 
## We can query the CLI to tell us what the names of the
## installed plugins are by running the 'create SanServer' 
## command. 
proc find_SCSI_Plugins {askUser type} {

    global testStep
    global send_human

    set pluginNameList []
    set allplugins ""    
    set myPlugin ""
    set mismatch "True"
    set timeout 900
    set andthis ""

    send_user "\nGathering the list of installed Storage Connect Plugins...\n"

    if {$type == "SCSI"} {
	send -h "list StorageArrayPlugin\r"
    } else {
	send -h "list FileServerPlugin\r"
    }
    sleep 5
    expect {
	-re "id:(.*?) name:(.*?)\n\r" { 
	    set output [string trim $expect_out(2,string)]
	    set allplugins [regsub -all -- "/" $output "//"] 
	    exp_continue
	}
	-re ".*OVM>" {}
	timeout {
	    send_user "Timeout received from OVM while attempting to view installed plugin data.\n"
	    send_user "Terminating.\n"
	    finishRun 1
	}
    }

    
    set pluginList [split $allplugins ","]
    
    ## If this is true, we're using a vendor supplied plugin
    ## so we want to ask the user which plugin to use.
    ## If it's not set, then we know we're just doing the
    ## generic plugin tests, and we'll just look for the 
    ## name of the generic plugin.
    if {$askUser == "True"} {
	
	set index 0
	set myVal ""
	set myPrompt "This is the complete list of Storage Connect plugins found by OVM.\n"
	
	foreach plugin $pluginList {   
	    append myPrompt "$index. $plugin\n"
	    incr index 1
	}
	
	append myPrompt "Please enter the number corresponding to the plugin\nname to be used in today's certification tests: "
	
	while {$mismatch == "True"} {
	    send_user "\n\n$myPrompt"
	    expect_user {
		-re "(\[0-9]+)\n" {
		    set userinput $expect_out(1,string);
		    set mismatch "False"
		}
		-re "(.*)\n" {
		    send_user "You entered an invalid choice.\n"
		}
		timeout {
		    send_error "The script has timed out after waiting 30 minutes for user input.\n"
		    send_error "Terminating.\n"
		    finishRun 1
		}
	    }
	}
	
	set myPlugin [lindex $pluginList $userinput]
	
	
    } else {
	foreach plugin $pluginList { 
	    if {[string match *eneric* $plugin]} {
		set myPlugin $plugin
		break
	    }
	}
    }
    
    return $myPlugin
}

## Add storage initiators to an Access Group on the Storage Array
proc addInitiators {ilist servername accessGroup} {
    
    global testStep
    global send_human

    send_user "\n## [incr testStep 1]. Adding the initiators from $servername to $accessGroup.\n"

    foreach initiator $ilist {	
	sleep 4
	send_verbose "Adding $initiator to $accessGroup.\n"
	send -h "add StorageInitiator id='$initiator' to AccessGroup name='$accessGroup'\r"
	validateCommandOutput "add StorageInitiator command"
	send_user "\n"
    }
}

proc findAccessGroups {} {

    global testStep
    global send_human
    global failureMsg
    global prompt

    set exitcode "False"
    
    send -h "list AccessGroup\r"
    sleep 5
    expect {  
        $failureMsg {
	    send_user "$expect_out(buffer)"
	    expect "*"	    
	    send_user "$expect_out(buffer)\n"
            set exitcode "False"}
        -re ".*None*" {
            send_verbose "Found no Access Groups...\n"
            set exitcode "False"}
        -re "id:(.*?) name:(.*?)\n\r" { 
            send_verbose "Found Access Group: $expect_out(2,string)\n"
            set agName $expect_out(2,string)
	    set exitcode "True"}
        -re "(.*)$prompt" {
	    set exitcode "True"}
    }
    
    expect "*"

    if {$exitcode == "False"} {
	send_user "An unexpected error has occurred while viewing Access Group information,"
        finishRun 1
    }

    return $agName
}

## Find a list of all of the servers which have been discovered
## by the Manager.
proc getServerIDs {} {

    global send_human
    global failureMsg
    global prompt
    set timeout 600

    array set myArray {}
    set x 0
    
    # Clear the expect buffer
    expect "*"

    # Get the name and id for the servers which have
    # been discovered by the manager.  We will need 
    # the IDs mapped to IP addresses to know which
    # disks are mapped, resources associated with, 
    # etc. to which ID.
    send -h "list server\r"
    sleep 4
    expect {
        $failureMsg {
	    send_user "$expect_out(buffer)"
	    expect "*"	    
	    send_user "$expect_out(buffer)\n"
            finishRun 1}
        -re "id:(.*?) name:(.*?)\n\r" {
            set myArray($x,id) [string trim $expect_out(1,string)];
            set myArray($x,name) [string trim $expect_out(2,string)];
            incr x 1;
            exp_continue}
        -re "(.*)$prompt" {}
        timeout {send_user "Unexpected error while viewing server info in proc getServerIDs\n"}
    }

    return [array get myArray]

}


proc findSource {vmName} {
    
    global testStep
    global send_human
    global failureMsg
    global prompt
    set timeout 600
    
    set myID ""

    send_user "\n## [incr testStep 1]. Determining on which server $vmName is currently running...\n"
    send -h "show vm name=$vmName\r"
    sleep 3
    expect {
        -re "Status: Failure" {
	    send_user "$expect_out(buffer)"
	    expect "*"	    
	    send_user "$expect_out(buffer)\n"
	    set myID "False"
	} 
	-re "Server = (.*?)  .*?\n\r" {
	    set myID [string trim $expect_out(1,string)]
	    send_verbose "Found the Source ID: $expect_out(1,string)\n"
	    exp_continue}
	-re "(.*)$prompt" {}
	timeout { 
	    send_user "An unexpected error occurred while attempting to view VM information.\n"
	    set myID "False"
	}
    }
    return $myID
}


proc verifyResize {diskList newsizes lunInfo} {
    upvar 1 $lunInfo myDict
    
    foreach disk $diskList {
	set thisSize [getDiskSize $disk]
	set index [lsearch $newsizes $thisSize]
	if {$index == -1} {
	    send_user "Unexpected LUN size!  Was expecting to find a "
	    printSizeList $newsizes 
	    send_user "LUN,\nand found a $thisSize"
	    send_user "GB LUN instead.  Terminating.\n\n"
	    return "False"
	} else {
	    set newsizes [lreplace $newsizes $index $index]
	    dict set myDict $disk size $thisSize
	}
    }
    
    return "True"
}


## The 
proc findClonedLUN {vmname diskmap} {

    global testStep
    global send_human
    global successMsg
    global failureMsg
    global prompt

    set timeout 600
    set mapID ""
    set diskID ""

    send -h "show VM name=$vmname\r"
    sleep 5
    expect {
        -re "Status: Failure" {
	    send_user "$expect_out(buffer)"
	    expect "*"	    
	    send_user "$expect_out(buffer)\n"
	    send_user "Fatal Failure while attempting to view details for $vmname\nTerminating!\n"
	    finishRun 1
	} 
	-re "VmDiskMapping (.*?) = (.*?)\n\r" {
	    set myMap $expect_out(1,string)
	    set myID $expect_out(2,string)
	    send_verbose "Found this diskmap: VmDiskMapping $myMap = $myID\n"
	    if {$diskmap == $myMap} {
		set mapID $myID
	    }
	    exp_continue
	}
	-re "(.*)$prompt" {}
    }

    ## Now we know the diskmap id, and from there we
    ## can find the disk id...
    send -h "show VmDiskMapping id=$mapID\r"
    sleep 5
    expect {
        -re "Status: Failure" {
	    send_user "$expect_out(buffer)"
	    expect "*"	    
	    send_user "$expect_out(buffer)\n"
	    send_user "Fatal Failure while attempting to view details the cloned LUN $mapID\nTerminating!\n"
	    finishRun 1
	} 
	-re "Virtual Disk Id = (.*?) .*?\n\r" {
	    set diskID $expect_out(1,string)
	    send_verbose "This disk is the cloned LUN: $diskID\n"
	    exp_continue
	}
	-re "(.*)$prompt" {}

    }

    expect "*"
    return $diskID
}

## Part of the clean up functionality.  Given the names of servers.
## find their IDs and delete them.
proc deleteServers {server1 server2} {

    global testStep
    global send_human
    global successMsg
    global failureMsg
    global prompt
    set timeout 900

    array set basicServerInfo [getServerIDs]
    set x [array size basicServerInfo]

    if {$x == 0} {
	return "None"
    }
    
    for {set i 0} {$i < $x} {incr i 1} {
	if {[info exists basicServerInfo($i,id)]} {
	    send_user "\n## [incr testStep 1]. Deleting $basicServerInfo($i,name)...\n"
	    send -h "delete server id=$basicServerInfo($i,id)\r"
	    sleep 5
	    expect {
		$successMsg {
		    send_user "$expect_out(buffer)"
		    expect "*"	    
		    send_user "$expect_out(buffer)\n"
		} 
		$failureMsg {
		    send_user "$expect_out(buffer)"
		    expect "*"	    
		    send_user "$expect_out(buffer)\n"
		    return "False"; 
		}
		-re "(.*)$prompt" {}
		timeout { 
		    send_user "OVMM Response Timeout: An unexpected error has occurred\n"
		    send_user "while executing the delete server command:\n"
		    send_user "Please refer to $logfile for additional details.\n\n";
		    return "False"
		}
	    }
	    
	    expect "*"
	}
    }

    return "True"
}

## Given a list of VM IDs, stop and delete all VMs. 
proc deleteVM {} {

    global testStep
    global send_human
    global failureMsg
    global prompt

    array set myVMs [getList VM]

    if {[array size myVMs] == 0} {
	return "None"
    }

    foreach vm [array names myVMs] {

	set myDiskMaps []

	send_user "\n## [incr testStep 1]. Attempting to stop VM ID: $vm....\n"
	send -h "stop vm id=$myVMs($vm)\r"
	showCommandOutput "stop vm command"
	
	send_user "\n"
	send_user "\n## [incr testStep 1]. Attempting to remove the VmDiskMappings from VM ID $vm....\n"
	send -h "show vm id=$myVMs($vm)\r"
	expect {
	    $failureMsg {
		send_user "$expect_out(buffer)"
		expect "*"	    
		send_user "$expect_out(buffer)\n"
		finishRun 1}	  
	    -re "(.*)$prompt" {
		set myString $expect_out(buffer)
	    }
	    timeout {finishRun 1}
	}
	
	## Strip the '[' and ']' characters from the string
	## because they make it hard to parse.
	set myString [string map {\[ __} $myString]
	set myString [string map {\] __} $myString]

	## regexp returns the string that was matched, plus the groupings.
	## In this case we can expect that for every match (exluding
	## IP Address), there will be three strings to with relevant
	## information: the matched string, the id, and the name.
	set vdiskMatches [regexp -all -inline -linestop "VmDiskMapping \[0-9]+ = (.*?) __\[^\n]*__" $myString]

	foreach {group0 group1} $vdiskMatches {
	    send_verbose "Found this VmDiskMapping: $group1\n"
	    lappend myDiskMaps [string trim $group1]
	} 

	foreach map $myDiskMaps {
	    send_user "\n## [incr testStep 1]. Deleting VmDiskMapping: $map\n"
	    send -h "delete vmDiskMapping id=$map\r"
	    validateCommandOutput "delete vmDiskMapping Command"
	}

	send_user "\n## [incr testStep 1]. Deleting Vm: $myVMs($vm)\n"
	send -h "delete vm id=$myVMs($vm)\r"
	validateCommandOutput "delete vm command"
	send_user "\n\n"
    }

    return "True"
}

## Given a list of Vnic IDs, delete those that exist. 
proc deleteVNICs {} {

    global testStep
    global send_human

    array set myVNICs [getList vnic]

    if {[array size myVNICs] == 0} {
	return "None"
    }

    foreach vnic [array names myVNICs] {
	send_user "\n## [incr testStep 1]. Deleting $vnic\n"
	send -h "delete vnic id=$myVNICs($vnic)\r"
	sleep 4
	validateCommandOutput "delete vnic command"
	send_user "\n\n"
    }

    return "True"
}

proc deleteNetwork {} {

    global testStep
    global send_human
    
    array set myNetworks [getList Network]

    if {[array size myNetworks] == 0} {
	return "None"
    }

    foreach network [array names myNetworks] {
	send_user "\n## [incr testStep 1]. Deleting $network\n"
	send -h "delete network id=$myNetworks($network)\r"
	validateCommandOutput "delete $network Network command"
	send_user "\n\n"
    }	

    return "True"
}

## Make sure the SAN Server has been defined before trying to delete it
proc deleteSANServer {} {

    global testStep
    global send_human
    
    array set mySANServers [getList StorageArray]

    if {[array size mySANServers] == 0} {
	return "None"
    }

    set unmanaged1 "Unmanaged FibreChannel Storage Array"
    set unmanaged2 "Unmanaged iSCSI Storage Array"

    foreach key [array names mySANServers] {
	switch -- $key \
	    $unmanaged1 {
		continue
	    } $unmanaged2 { 
		continue
	    } default {
		send_user "\n## [incr testStep 1]. Deleting $key\n"
		send -h "delete StorageArray id=$mySANServers($key)\r"
		validateCommandOutput "delete StorageArraycommand"
		send_user "\n\n"
	    }
    }
    
    return "True"
}

## Make sure the File Server has been defined before trying to delete it
proc deleteFileServer {} {

    global testStep
    global send_human
    
    array set myFileServers [getList FileServer]

    if {[array size myFileServers] == 0} {
	return "None"
    }

    foreach key [array names myFileServers] {
	send_user "\n## [incr testStep 1]. Deleting $key\n"
	send -h "delete FileServer id=$myFileServers($key)\r"
	validateCommandOutput "delete FileServer command"
	send_user "\n\n"
    }

    return "True"
}

proc deleteStragglerLUNs {} {

    global send_human
    global failureMsg
    global testStep
    global prompt

    set timeout 600
    set myLeftoverLUNs []

    expect "*"

    send_user "\n## [incr testStep 1]. Getting the list of PhysicalDisks....\n"
    send -h "list PhysicalDisk\r"
    sleep 5
    expect {  
        $failureMsg {
	    send_user "$expect_out(buffer)"
	    expect "*"	    
	    send_user "$expect_out(buffer)\n"
	}
        -re ".*None*" {
            send_user "Found no PhysicalDisks...\n"}
        -re "id:(.*?) name:(.*?)\n\r" { 
            send_user "Found PhysicalDisk: $expect_out(2,string)\n"
            lappend myLeftoverLUNs [string trim $expect_out(1,string)]
            exp_continue}
        -re "(.*)$prompt" { }
    }

    
    if {[llength $myLeftoverLUNs] == 0} {
	return "None"
    }

    foreach lun $myLeftoverLUNs {
	send_user "\n## [incr testStep 1]. Deleting LUN straggler: disk=$lun\n"
	send -h "delete PhysicalDisk id=$lun\r"
	validateCommandOutput "delete PhysicalDisk command"
    }

    return "True"

}


## Given a list of repository names, find and delete the contents
## of the repository, then delete the repository.
proc deleteRepo {} {

    global testStep
    global send_human
    global failureMsg
    global prompt
    set timeout 600

    array set myRepos [getList Repository]

    if {[array size myRepos] == 0} {
	return "None"
    }
   
    set serverList []
    set vmTemplateList []
    set assemblyList []
    set virtualCdromList []
    set virtualDiskList []
    set vmList []      

    set found 0

    foreach repo [array names myRepos] {
	send -h "show repository id=$myRepos($repo)\r"
	sleep 5
	expect {
	    $failureMsg {
		send_user "$expect_out(buffer)"
		expect "*"	    
		send_user "$expect_out(buffer)\n"
		return "False"} 
	    -re "(.*)$prompt" {
		set myString $expect_out(buffer)
	    }
	    timeout {
		send_user "Unexpected error occurred while viewing $repo\n"
		finishRun 1}
	}

	## Strip the '[' and ']' characters from the string
	## because they make it hard to parse.
	set myString [string map {\[ __} $myString]
	set myString [string map {\] __} $myString]
	
	set presentedMatches [regexp -all -inline -linestop "Presented Server \[0-9]+ = (.*?)  __\[^\n]*__" $myString]
	set templateMatches [regexp -all -inline -linestop "Vm \[0-9]+ = (.*?)  __\[^\n]*__" $myString]
	set assemblyMatches [regexp -all -inline -linestop "Assembly \[0-9]+ = (.*?)  __\[^\n]*__" $myString]
	set isoMatches [regexp -all -inline -linestop "VirtualCdrom \[0-9]+ = (.*?)  __\[^\n]*__" $myString]
	set vdiskMatches [regexp -all -inline -linestop "VirtualDisk \[0-9]+ = (.*?)  __\[^\n]*__" $myString]
	set filesystemMatch [regexp -all -inline -linestop "File System = (\[0-9a-f]+)" $myString]

	foreach {group0 group1} $presentedMatches {
	    send_verbose "Repository is presented to this server: $group1\n"
	    lappend serverList [string trim $group1]
	}
	foreach {group0 group1} $templateMatches {
	    send_verbose "Found this Template/VM: $group1\n"
	    lappend vmTemplateList [string trim $group1]
	}
	foreach {group0 group1} $assemblyMatches {
	    send_verbose "Found this Assembly: $group1\n"
	    lappend assemblyList [string trim $group1]
	}
	foreach {group0 group1} $isoMatches {
	    send_verbose "Found this ISO image: $group1\n"
	    lappend virtualCdromList [string trim $group1]
	}
	foreach {group0 group1} $vdiskMatches {
	    send_verbose "Found this Virtual Disk: $group1\n"
	    lappend virtualDiskList [string trim $group1]
	}
	foreach {group0 group1} $filesystemMatch {
	    send_verbose "Found this Filesystem: $group1\n"
	    set myFilesystem [string trim $group1]
	}


	if {[llength serverList] == 0} {
	    send_user "Repository: $repo is not presented to any servers, and therefore\n"
	    send_user "cannot have its contents removed or be deleted.\n"
	    return "False"
	}

	if {[llength $vmList] > 0} {
	    send_user "\n## [incr testStep 1]. Stopping and deleting all VMs associated with repository: $repo...\n"
	    foreach object $vmList {
		send -h "stop vm id=$object\r"
		sleep 5
		showCommandOutput "stop vm command"
		send_user "\n"
		send -h "delete vm id=$object\r"
		sleep 4
		validateCommandOutput "delete vm command"
		send_user "\n\n"
	    }
	}

    
	if {[llength $vmTemplateList] > 0} {
	    send_user "\n## [incr testStep 1]. Deleting all Templates associated with repository: $repo...\n"
	    foreach object $vmTemplateList {
		send -h "delete vm id=$object\r"
		sleep 4
		validateCommandOutput "delete vm command"
		send_user "\n"
	    }
	}
    
	    
	if {[llength $virtualDiskList] > 0} {
	    send_user "\n## [incr testStep 1]. Deleting all Virtual Disks associated with repository: $repo...\n"
	    foreach object $virtualDiskList {
		send -h "delete virtualdisk id=$object\r"
		sleep 4
		validateCommandOutput "delete VirtualDisk command"
		send_user "\n"
	    }
	}
    
	if {[llength $virtualCdromList] > 0} {
	    send_user "\n## [incr testStep 1]. Deleting all present ISO images, CDROMs, and DVDs associated with repository: $repo...\n"
	    foreach object $virtualCdromList {
		send -h "delete virtualcdrom id=$object\r"
		sleep 4
		validateCommandOutput "delete VirtualCdrom command"
		send_user "\n"
	    }
	}
	    
	
	if {[llength $assemblyList] > 0} {
	    send_user "\n## [incr testStep 1]. Deleting all Assemblies associated with repository: $repo...\n"
	    foreach object $assemblyList {
		send -h "delete assembly id=$object\r"
		sleep 4
		validateCommandOutput "delete assembly command"
		send_user "\n"
	    }
	}

	sleep 5
	    
	send_user "\n## [incr testStep 1]. Deleting Repository ID: $repo\n"
	send -h "delete repository id=$myRepos($repo)\r"
	validateCommandOutput "delete repository command"
    
	send_user "\n## [incr testStep 1]. Deleting the Repository Filesystem: $myFilesystem\n"
	send -h "delete fileSystem id=$myFilesystem\r"
	validateCommandOutput "delete FileSystem command"


	unset serverList
	unset vmTemplateList
	unset assemblyList
	unset virtualCdromList
	unset virtualDiskList
	unset vmList
	
	set serverList []
	set vmTemplateList []
	set assemblyList []
	set virtualCdromList []
	set virtualDiskList []
	set vmList []     

    }

    return "True"
}

## Given a list of Server Pool names, remove all servers from
## the server pool, and then delete.
proc deleteServerpool {} {

    global testStep
    global send_human
    global failureMsg
    global prompt
    set timeout 600

    array set myPools [getList ServerPool]

    set blarf [array size myPools]
    if {[array size myPools] == 0} {
	return "None"
    }   

    set serverList []
    set poolFSList []
    set masterServer ""
    set serverCount ""

    foreach pool [array names myPools] {
	send_verbose "Determining servers in Server Pool: $pool....\n"
	send -h "show serverpool id=$myPools($pool)\r"
	sleep 4
	expect {
	    $failureMsg {
		send_user "$expect_out(buffer)"
		expect "*"	    
		send_user "$expect_out(buffer)\n"
		return "False"}
	    -re "(.*)$prompt" {
		set myString $expect_out(buffer)
	    }
	    timeout {
		send_user "Unexpected error occurred while viewing $pool\n"
		finishRun 1}
	}

	## Strip the '[' and ']' characters from the string
	## because they make it hard to parse.
	set myString [string map {\[ __} $myString]
	set myString [string map {\] __} $myString]
	
	set serverMatches [regexp -all -inline -linestop "Server \[0-9]+ = (.*?)  __\[^\n]*__" $myString]
	set masterMatches [regexp -all -inline -linestop "Master Server = (.*?) __\[^\n]*__" $myString]
	set poolFSMatches [regexp -all -inline -linestop "PoolFileSystem = (.*? $pool)" $myString]

	foreach {group0 group1} $serverMatches {
	    send_verbose "Found this server in the pool: $group1\n"
	    lappend serverList [string trim $group1]
	}
	foreach {group0 group1} $masterMatches {
	    send_verbose "This is the master server: $group1\n"
	    set masterServer [string trim $group1]
	}
	foreach {group0 group1} $poolFSMatches {
	    send_verbose "Found this File System: $group1\n"
	    lappend poolFSList [string trim $group1]
	}

	send_user "\n## [incr testStep 1]. Removing servers from $pool\n"
	foreach server $serverList {
	    if {$server == $masterServer} {
		send_verbose "Leaving the master server in the pool until\n"
		send_verbose "all other servers have been deleted.\n"
		continue
	    } else {
		send -h "remove server id=$server from serverpool id=$myPools($pool)\r"
		sleep 3
		validateCommandOutput "remove server command"
	    } 
	}

	
	send_user "\n## [incr testStep 1]. Deleting the File Systems from $pool\n"
	foreach fs $poolFSList {
	    send -h "delete fileSystem id='$fs'\r"
	    validateCommandOutput "delete FileSystem command"
	}
	    
	if { $masterServer != "" } {
	    send_user "\n## [incr testStep 1]. Removing the master server from $pool\n"
	    send -h "remove server id=$masterServer from serverpool id=$myPools($pool)\r"
	    sleep 3
	    validateCommandOutput "remove server command"
	}
	    
	send_user "\n## [incr testStep 1]. Deleting the Server Pool: $pool\n"
	send -h "delete serverpool id=$myPools($pool)\r"
	sleep 3
	validateCommandOutput "delete serverpool command"
    
	set serverList []
	set masterServer ""
	set serverCount ""
    }

    return "True"
}

## Given an object type (Server, VM, PhysicalDisk, etc.) get 
## a list of all Object IDs known to the Manager for that
## object type.
proc getList {object} {

    global testStep
    global send_human
    global failureMsg
    global prompt

    set timeout 600

    set exitcode "False"
    array set myObj {}

    expect "*"

    send -h "list $object\r"
    sleep 5
    expect {  
        $failureMsg {
	    send_user "$expect_out(buffer)"
	    expect "*"	    
	    send_user "$expect_out(buffer)\n"
            set exitcode "False"}
        -re ".*None*" {
            send_verbose "Found no $object objects...\n"
            set exitcode "True"}
        -re "id:(.*?) name:(.*?)\n\r" { 
            send_verbose "Found $object: $expect_out(2,string)\n"
            set myObj([string trim $expect_out(2,string)]) [string trim $expect_out(1,string)]
	    set exitcode "True"
            exp_continue}
        -re "(.*)$prompt" {
	    set exitcode "True"}
    }
    

    if {$exitcode == "False"} {
	send_user "An unexpected error has occurred while viewing $object information,"
        finishRun 1
    }

    return [array get myObj]
}

## Copy logs from one of the OVM servers to 
## our log directory for inclusion in the 
## tarball that gets sent back to Oracle.
proc copyLog {server password filename logdir newfilename} {

    global send_human
    set match_max 10000
    set success "True"
    set timeout -1

    set myString "root\@$server\:$filename"
    append logdir $newfilename

    expect "*"
    
    spawn scp $myString $logdir; set spawn_id1 $spawn_id
    sleep 5
    expect {
	-i $spawn_id1 -re ".*Are you sure you want to continue connecting.*?" {
	    send_user "$expect_out(buffer)\nSending yes to the host....\n"; 
	    send -h "yes\r";
	    exp_continue
	}  
	-i $spawn_id1 -re ".+? password:" {
	    send_user "\nSending password...\n"; 
	    send -h "$password\r";
	    exp_continue
	}
	-i $spawn_id1 -re ".+? No route to host\r" {
	    send_user "Failed to connect to $server: No route to host.\n"
	    send_user "Please check your network connection and try again.\n"
	    set success "False"
	}
	-i $spawn_id1 -re ".*Permission denied, please try again.*" {
	    send_user "$expect_out(buffer)\nUnable to login to the OVM Manager using the admin password provided.\n"
	    send_user "Please verify that the password is correct and run the script again.\n\n"
	    set success "False"
	}
	-i $spawn_id1 -re "Connection closed .+?\r" {
	    send_user "\nFailed to connect to $server: Connection closed by remote host.\n"
	    set success "False"
	}
	-i $spawn_id1 -re ".+? No such file or directory\r" {
	    send_user "\nFailed to copy $filename: No such file or directory!\n"
	    set success "False"
	}
	
    }
    
    return $success

}


## Collect server data using sosreport.  Login to each 
## of the OVS servers and run sosreport, then send the
## full path to the results file back so that the 
## report can be copied to the log directory. 
proc runSOS {server logdir ticket mySpawnID} {

    global send_human
    set match_max 10000
    set timeout 600
    set soshome "/tmp/"
    set success "true"

    send_user "\nExecuting sosreport; this can take several minutes...\n"
    send -i $mySpawnID -h "sosreport --batch --ticket-number='$ticket' --name='$server' --tmp-dir=$soshome\r"
    sleep 5
    expect {
	-i $mySpawnID -re "usage: .+?" {
	    send -h "sosreport --batch --ticket-number='$ticket' --name='$server'\r"
	    exp_continue
	}
	-i $mySpawnID -re "^sosreport .+?" {
	    exp_continue;
	}
	-i $mySpawnID -re "(/tmp/)(sosreport\-.+?\r)" {
	    set soshome $expect_out(1,string)
	    set sosreport $expect_out(1,string)
	    append sosreport $expect_out(2,string)
	    set sosname $expect_out(2,string)
	    exp_continue
	}
	-i $mySpawnID -re "The md5sum is: (.+?)\r" {
	    set md5sum $expect_out(1,string)
	    exp_continue
	}
	-i $mySpawnID "Please send this file to your support representative." { set success "True" }
	timeout {
	    set sosreport "False"
	}
    }
    

    if {$sosreport == "False"} {
	send_user "Watchdog timeout after 15 minutes: sosreport did not complete!\n"
	return $sosreport
    }


    ### The name of the sosreport is long, and when we try to
    ### copy it to the machine where the log directory is
    ### the length of the string used to spawn the scp command
    ### overflows expect's send buffer, and prevents the
    ### command from being executed correctly.  Since it's 
    ### important to preserve the name of the sosreport, the 
    ### workaround is to create a tarball with a shorter name
    ### that can be copied without overflowing the buffer.
    send_user "sosreport was generated in: $sosreport\n"
    send_user "The md5sum for the sosreport is: $md5sum\n\n"
    send_user "Now creating a tarball with the sosreport so that it can be copied to the log directory...\n"


    set tarname "$soshome$server-soreport.tar"
    send_user "Creating the new tarball....\n"

    set timeout 60
    send -i $mySpawnID -h "tar -cf $tarname $sosreport\r"
    expect {
	-i $mySpawnID -re "tar: .+?: No such file or directory\r" { 
	    set success "False"; 
	    send_user "\n\nCreation of the tarball failed: no such file or directory.\n" 
	}
	-i $mySpawnID "tar: Error exit delayed from previous errors\r" {
	    set success "False";
	    send_user "\n\nCreation of the tarball failed: Exit delayed from previous errors.\n" 
	}
	-i $mySpawnID "tar: Removing leading `/' from member names\r" {
	    set success "True"
	}
    }

    if {$success == "False"} {
	return $success
    } else {	
	return $tarname
    }
}

## We also want to chat with multipathd to see how
## it's configured.  Copy the output to a file
## so that we can keep that with all of the logs.
proc runMultipathd {filename mySpawnID} {

    global send_human
    set success "False"

    ## Since we're redirecting all of the output to a file, we have
    ## no way to know if the call to multipathd succeeded or failed.
    ## so we just try to clear the expect buffer after the call so
    ## that we can read from it later
    send_user "Sending multipathd command.  This will take a moment...\n"
    send -i $mySpawnID -h "echo \"show config\" | multipathd -k > $filename\r"
    expect {
	-i $mySpawnID -re "(.*)\r" {
	   exp_continue
	}
    }

    expect "*"
    sleep 20

    ## Since this file is on a remote server, we can't just
    ## use the tcl "file exists" function to see if the output
    ## file was written, but since we're already logged into 
    ## this machine, why not just use file to tell us if the 
    ## the output file exists and is a txt file, as expected?
    send_verbose "Verifying output was captured in $filename...\n"
    send -i $mySpawnID -h "file $filename\r"
    expect {
	-i $mySpawnID -re "Usage: .*?" {
	    send_verbose "Failed capturing output from multipathd.\n"
	}
	-i $mySpawnID -re ".*?Error:.*?No such file or directory.*?\r" {
	    send_verbose "Failed capturing output from multipathd.\n"
	}
	-i $mySpawnID -re "(.*?)$filename: ASCII text\r" {
	    set success "True"
	    send_verbose "multipathd output was captured successfully.\n"	    
	}
    }

    expect "*"
    return $success

}


## This is especially for handling the sosreports, 
## we need to be able to grab the filename out of
## the full path
proc getFileName {fullpath} {

    set filename "False"

    set mypath [string trimright $fullpath "/"]
    set chunks [split $fullpath "/"]
    set numchunks [llength $chunks]
    
    if {$numchunks >= 1} {
	set filename [lindex $chunks [expr $numchunks - 1]]
    } 

    return $filename
}

proc tallyResults {} {

    global testList
    global testStatus

    if {[info exists testList] != 0} {

	send_user "\n--------------------------------------------------------------------------\n"
	send_user "\n\nIndividual Test Case Results:\n"
	
	foreach test $testList {
	    send_user "$test ................................ $testStatus($test,status)\n"	
	}
    }

    return
}

## This function is used to create multiple LUNs at a 
## time, utilizing the Vendor Plugin.  LUN names will be
## unique, based on a timestamp string passed in as the
## "name" variable.  As the LUNs are created, information
## about them will be stored in a dictionary, which will
## be returned to the script. 
proc createLUNs_VP {name volgroup sizelist} {

    set luncount 0
    set myVolGroup [regsub -all -- "/" $volgroup "//"] 

    ## Get the list of existing LUN IDs.  We'll need to
    ## be able to verify against this in the event that
    ## we can't get the ID when the LUN is created.
    #array set knownluns [getList "physicalDisk"]

    ## Loop through the size list, creating the LUNs
    foreach size $sizelist {

	incr luncount 1
	set mySize [string map { \{ "" \} "" } $size]
	set myName ${name}_${mySize}G
	set myName [string map { \{ "" \} "" } $myName]
	set retval [createLUN $myName $mySize $myVolGroup] 

	## make sure we found the LUN ID
	if {$retval == "False"} {
	    # The LUN was created, but we didn't get its ID
	    array set knownluns [getList "physicalDisk"]

	    ## Get the list of LUNs and look for the new LUN
	    ## by its name.
	    if {[info exists knownluns($myName)] == 1} {
		set myID $knownluns($myName)
		send_user "Found this id: $myID\n"
		array set myLUN_info [list lun_name $myName lun_size $mySize lun_id $myID]
	    } else {
		## If we still don't find the ID, bail out of the test
		send_user "Even though OVM reported that a LUN was created,\nthe ID for the LUN $myName can't be found!\nTerminating.\n"
		finishRun 1
	    }
	    
	    ## Cleanup the array so that we always
	    ## have fresh information.
	    array unset knownluns

	} else {
	    array set myLUN_info $retval
	}

	## add the information to the dictionary
	foreach key [array names myLUN_info] {
	    dict set myLUNs $luncount $key $myLUN_info($key)
	}

	## Cleanup the array so that we always
	## have fresh information.
	array unset myLUN_info

    }

    ## return the dictionary
    return $myLUNs
}

proc createLUN {name size volgroup} {

    global testStep
    global send_human
    global logfile
    global successMsg
    global failureMsg
    set timeout 890
    append mySize $size "G"

    send_user "\n## [incr testStep 1]. Creating a new $mySize LUN: $name on the volumeGroup '$volgroup'"
    send -h "create physicaldisk name=$name shareable=no size=$size thinProvision=yes on volumeGroup name='$volgroup'\r"
    sleep 3
    expect {
        $successMsg {
	    send_user "$expect_out(buffer)"
	    expect "*"	    
	    send_user "$expect_out(buffer)\n"
	} 
        $failureMsg {
	    send_user "$expect_out(buffer)"
	    expect "*"	    
	    send_user "$expect_out(buffer)\n"
	    send_user "Fatal Failure while attempting to create a PhysicalDisk!\nTerminating.\n"
	    finishRun 1
	} 
        timeout {
	    send_user "\nWatchdog Timeout: The create PhysicalDisk command failed\n"
            send_user "to complete after more than 15 minutes.  The OVM CLI terminates\n"
	    send_user "idle connections after 15 minutes, and therefore the script has\n"
	    send_user "been terminated to avoid further failures.\n\n"
	    send_user "Please refer to $logfile for additional details.\n\n";
            finishRun 1
	}
    }


    expect "*"
    send_user "\nFinding the ID for the newly created LUN...\n"
    send -h "show PhysicalDisk name=$name\r"
    expect {
        $successMsg {
	    send_user "$expect_out(buffer)"
	    expect "*"	    
	    send_user "$expect_out(buffer)\n"
	} 
        $failureMsg {
	    send_user "$expect_out(buffer)"
	    expect "*"	    
	    send_user "$expect_out(buffer)\n"
	    send_user "Fatal Failure while attempting to view PhysicalDisk $name!\nTerminating.\n"
	    finishRun 1
	} 
        timeout {
	    send_user "\nWatchdog Timeout: The create PhysicalDisk command failed\n"
            send_user "to complete after more than 15 minutes.  The OVM CLI terminates\n"
	    send_user "idle connections after 15 minutes, and therefore the script has\n"
	    send_user "been terminated to avoid further failures.\n\n"
	    send_user "Please refer to $logfile for additional details.\n\n";
            finishRun 1
	}
    }
    set myID "0"
    regexp {Id = ([a-f0-9]+) } $output -> myID

    if {$myID == "0"} {
	return "False"
    }

    array set myLUN_info [list lun_name $name lun_size $size lun_id $myID]
    expect "*"
    return [array get myLUN_info]

}

proc getLUNInfo {basename sizelist} {

    global testStep
    global send_human
    global logfile
    global successMsg
    global failureMsg

    set luncount 0
    array set knownluns [getList "physicalDisk"]

    foreach size $sizelist {

	incr luncount 1	
	set mySize [string map { \{ "" \} "" } $size]
	set myName ${basename}_${mySize}G
	set myName [string map { \{ "" \} "" } $myName]


	## Look for the LUN by its name, then we can get 
	## its ID.
	if {[info exists knownluns($myName)] == 1} {
	    set myID $knownluns($myName)
	    send_user "Found this id: $myID\n"
	    array set myLUN_info [list lun_name $myName lun_size $mySize lun_id $myID]
	} else {
	    ## If we can't find the ID, bail out of the test
	    ## because that means the LUN no longer exists
	    ## according to OVM, and we still are expecting 
	    ## to do operations on this LUN...
	    send_user "Expected to find info for LUN $myName, but it wasn't in OVMs list of PhysicalDisks.\nTerminating."
	    finishRun 1
	}
   
	## add the information to the dictionary
	foreach key [array names myLUN_info] {
	    dict set myLUNs $luncount $key $myLUN_info($key)
	}

	## Cleanup the array so that we always
	## have fresh information.
	array unset myLUN_info
    }

    ## return the dictionary
    return $myLUNs
}
    

proc passwdQuery {serverList serverInfo} {
    upvar 1 $serverInfo myServers

    set samepwd "False"
    set again "True"
    set userinput ""
    set userinput2 ""
    set mismatch "True"
    set extra ""

    send_user "This script will login to the OVM Manager and OVS servers\n"
    send_user "in order to gather OVM Admin, CLI, and ovs-agent logs.\n"
    send_user "Additionally on the OVS servers, sosreports and multipath\n"
    send_user "information will be gathered.\n\n"
    send_user "\n"
    
    while {$again == "True"} {
	send_user "Is the root password the same for all three machines? (yes|no) "
	set data [gets stdin]

	if {$data == "Yes" || $data == "yes"} {
	    set samepwd "True"
	    set again "False"
	} elseif {$data == "no" || $data == "No"} {
	    set samepwd "False"
	    set again "False"
	} else {
	    send_user "Please type 'yes' or 'no'\n"
	}
    }

    if {$samepwd == "True"} {
	set myPass [getPassWD "root"]
	foreach server $serverList {
	    dict set myServers $server myPassWD $myPass
	}
    } else {
	foreach server $serverList {
	    dict set myServers $server myPassWD [getPassWD "root@$server"]
	}
    }
}


proc getPassWD {myPrompt} {

    set mismatch "True"
    set userinput ""
    set userinput2 ""
    stty -echo echonl

    send_user "\n"
    while {$mismatch == "True"} {

	send_user "HCL> Please enter the password for $myPrompt: "
	set userinput [gets stdin]

	send_user "HCL> Please enter the password for $myPrompt (confirm): "
	set userinput2 [gets stdin]

	if {$userinput == $userinput2} {
	    set mismatch "False"
	} else {
	    send_error "The passwords did not match!\n"
	    set mismatch "True"
	}
    }

    stty sane
    return $userinput
}


## Cleanly exit from the script.
proc finishRun {exitcode} {

    ## For exit codes 0 (successful finish), and 2 (failure of an OVM command)
    ## we need to close the ssh session manually.  Other exit codes mean 
    ## something else like a timeout, or a crash, or expect operating
    ## on ovm output out of order, etc., has occurred; in which case, the ssh 
    ## session has already been terminated...
    if {$exitcode == 0} {
	send_user "\nExiting.\n\n"
	close
    }

    if {$exitcode == 1} {
	send_user "\n\nA fatal error has been encountered, from which recovery is impossible at this time.\nExiting.\n\n"
	close
    }	

    tallyResults    

    # Close down the logfile.
    log_file

    exit $exitcode
}

trap {
    ## Since we play with stty settings, make
    ## sure to make them sane if we receive
    ## keyboardinterrupt.
    stty sane
    send_user "\nCaught user requested interrupt.\nTerminating...\n"
    exit 1
} SIGINT
    
