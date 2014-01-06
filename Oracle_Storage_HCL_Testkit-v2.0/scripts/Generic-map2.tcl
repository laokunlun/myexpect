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

#################################################################
##
##       Test Suite 1: Generic Plugin tests over iSCSI and FC
##
#################################################################
##      This is what we're going for....
##
##      +-----+-------+---------------+-------------+
##      | LUN | Size  | OVM Server 1 | OVM Server 2 |
##      +-----+-------+--------------+--------------+
##      |  1  |  7 GB |   deleted    |              |
##      |  2  | 12 GB |              |   deleted    |
##      |  3  |  2 GB |    Mapped    |    Mapped    |
##      |  4  |  5 GB |    Mapped    |    Mapped    |
##      |  5  | 10 GB |    Mapped    |    Mapped    |
##      |  6  | 30 GB |    Mapped    |    Mapped    |
##      +-----+-------+--------------+--------------+
##

OVMlogin
set testStep 0
set lunList []

refreshLUNs $is_iscsi $lunList $serverNames $myServers

set sizelist {2 5 10 30}
set expectedMap 4
set expectedUnmap 0
set shared 0
set lunList []

foreach server $serverNames {

    send_user "\n## [incr testStep 1]. Verifying the new LUNs have been mapped to $server...\n"
    set newMaps []
    set myID [dict get $myServers $server server_id]
    
    set origDisk [dict get $myServers $server phys_disks]
    set mappedDisks [getDisks $server $myID]

    # Verify that the newly mapped disk list is larger than
    # the list of disks found when the servers were discovered.
    if {[llength $origDisk] >= [llength $mappedDisks]} {
    	send_user "FAILURE: No new LUNs were found on $server!\n"
    	finishRun 1
    }

    foreach lun $mappedDisks {
	# Look for the new disks.
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

    set success [verifyExpectedMaps $newMaps $expectedMap $expectedUnmap $sizelist]
    if {$success == "False"} {
	finishRun 4
    }

    unset newMaps
    unset origDisk
    unset mappedDisks
    
}

if {$shared != 4} {
    send_user "There are four LUNs mapped to each server, but they\n"
    send_user "are not the same four LUNs.  The test requirement\n"
    send_user "is to map the the same four LUNs to both OVS servers.\n"
    send_user "This is a failure condition.\nTerminating.\n"
    finishRun 1
} else {
    send_user "\n\nThe LUNs have been correctly mapped to $masterName and $slaveName!\n"
}

close
