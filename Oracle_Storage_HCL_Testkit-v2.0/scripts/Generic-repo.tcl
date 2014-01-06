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

############################################################################
##
##       Test Suite 1: iSCSI with Generic Plugin
##
############################################################################
##
##      +-----+-------+--------------+--------------+---------------+
##      | LUN | Size  | OVM Server 1 | OVM Server 2 |     Usage     |
##      +-----+-------+--------------+--------------+---------------+
##      |  1  |  7 GB |              |              |               |
##      |  2  | 12 GB |              |              |               |
##      |  3  |  2 GB |              |              |               |
##      |  4  | 15 GB |    Mapped    |    Mapped    |     PoolFS    |
##      |  5  | 20 GB |    Mapped    |    Mapped    |               |
##      |  6  | 30 GB |    Mapped    |    Mapped    |   Repository  |
##      +-----+-------+--------------+--------------+---------------+
##

OVMlogin
set testStep 0

dict for {id info} $lunInfo {
    dict with info {
	if {$size == "15" && $is_shared == "True"} { 
	    set poolFSDiskID $id
	} elseif {$size == "30" && $is_shared == "True"} {
	    set repoDiskID $id
	} elseif {$size == "20" && $is_shared == "True"} {
	    set sharedDiskID $id
	} else {
	    continue
	}
    }
}

if {$poolFSDiskID == ""} {
    send_user "Fatal Failure: Did not find a 15G disk that is shared between\n"
    send_user "$masterName and $slaveName\n"
    send_user "to use for the Pool Filesystem!  Terminating!\n"
    finishRun 1
} 
if {$repoDiskID == ""} {
    send_user "Fatal Failure: Did not find a 30G disk that is shared between\n"
    send_user "$masterName and $slaveName\n"
    send_user "to use for the Repository!  Terminating!\n"
    finishRun 1
} 
if {$sharedDiskID == ""} {
    send_user "Fatal Failure: Did not find a 20G disk that is shared between\n"
    send_user "$masterName and $slaveName\n"
    send_user "to use for the VM disk!  Terminating!\n"
    finishRun 1
}

set myLocalFileServer [findLocalFileServer $masterName]
if {$myLocalFileServer == "False"} {
    send_user "Fatal Failure: Could not find a local FileServer\n"
    send_user "on $masterName.  This will prevent\n"
    send_user "all actions with the repsitory to fail.\nTerminating.\n"
    finishRun 1
}

send_user "\n## [incr testStep 1]. Refreshing PhysicalDisk $poolFSDiskID for use as the Pool Filesystem\n"
send -h "refresh PhysicalDisk id=$poolFSDiskID\r"
validateCommandOutput "refresh PhysicalDisk command"

send_user "\n## [incr testStep 1].  Creating a clustered ServerPool on LUN $poolFSDiskID\n"
send -h "create ServerPool virtualIP=$serverPoolIP clusterEnable=yes physicalDisk=$poolFSDiskID name=$serverPoolName\r"
validateCommandOutput "create ServerPool command"


foreach server $serverNames {
    set myID [dict get $myServers $server server_id]

    send_user "\n## [incr testStep 1].  Adding $server to $serverPoolName\n"
    send -h "add server id=$myID to serverpool name='$serverPoolName'\r"
    validateCommandOutput "add Server to ServerPool"
}

set repoID [createRepositoryOnSAN $myLocalFileServer $repoFSName $repoDiskID $repoName]
if {$repoID == "False"} {
    send_user "Could not create a Repository on LUN $repoDiskID\n"
    finishRun 1
}


foreach server $serverNames {
    set myID [dict get $myServers $server server_id]

    send_user "\n## [incr testStep 1]. Presenting the repository $repoName to $server\n"
    send -h "add server id=$myID to Repository id=$repoID\r"
    validateCommandOutput "add Server to Repository command"
}

send_user "\n## [incr testStep 1]. Refreshing the repository $repoName\n" 
send -h "refresh Repository id=$repoID\r"
validateCommandOutput "refresh repository command"

close

