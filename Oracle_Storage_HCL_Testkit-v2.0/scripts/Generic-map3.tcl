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

##########################################################################
##
##       Test Suite 1: iSCSI or FibreChannel with Generic Plugin
##
##########################################################################
##
##      +-----+-------+-------+--------------+--------------+
##      | LUN |  Old  |  New  | OVM Server 1 | OVM Server 2 |
##      +-----+-------+-------+--------------+--------------+
##      |  1  |  7 GB |       |              |              |
##      |  2  | 12 GB |       |              |              |
##      |  3  |  2 GB |       |   Unmapped   |   Unmapped   |
##      |  4  |  5 GB | 15 GB |    Mapped    |    Mapped    |
##      |  5  | 10 GB | 20 GB |    Mapped    |    Mapped    |
##      |  6  | 30 GB |       |    Mapped    |    Mapped    |
##      +-----+-------+-------+--------------+--------------+

OVMlogin
set testStep 0

foreach lun $lunList {
    dict set lunInfo $lun size [getDiskSize $lun]
}

refreshLUNs $is_iscsi $lunList $serverNames $myServers

send_user "\nBegining LUN state verification.  Unmapped LUNs will be deleted from the OVM manager.\n"
set dcount [deleteLUNs lunList lunInfo]
if {$dcount == 1} {
    send_user "Successfully deleted the 2GB LUN from $masterName "
    send_user "and $slaveName.\n"
    send_user "Waiting 30 seconds for everything to settle....\n\n"
    sleep 30
} else {
    send_user "Expected one unmapped LUN, "
    send_user "but found $dcount unmapped LUNs; all of which have been deleted!\n"
    finishRun 1
}

send_user "Now verifying the resizing on the remaining disks...\n"

set sizelist {15 20 30}
if {[verifyResize $lunList $sizelist lunInfo] == "False"} {
    finishRun 1
} else {
    send_user "The LUNs have been correctly resized.\n"
}

send_user "Resizing and unmapping was successful.  Continuing.\n"
close
