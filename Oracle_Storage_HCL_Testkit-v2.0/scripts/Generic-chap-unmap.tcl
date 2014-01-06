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
##      This is what we're going for....
##
##      +-----+-------+---------------+---------------+
##      | LUN | Size  | OVM Server #1 | OVM Server #2 |
##      +-----+-------+---------------+---------------+
##      |  1  |  7 GB |   unmapped    |   unmapped    |
##      |  2  | 12 GB |   unmapped    |   unmapped    |
##      +-----+-------+---------------+---------------+
##


OVMlogin
set testStep 0

refreshLUNs $is_iscsi $lunList $serverNames $myServers

send_user "\nBegining LUN state verification.  Unmapped LUNs will be deleted from the OVM manager.\n"
set dcount [deleteLUNs lunList lunInfo]
if {$dcount == 2} {
    send_user "Successfully deleted both LUNs from $masterName "
    send_user "and $slaveName.\n"
    send_user "Waiting 120 seconds for everything to settle....\n\n"
    sleep 120
} else {
    send_user "Expected two unmapped LUNs, "
    send_user "but found $dcount unmapped LUNs; all of which have been deleted!\n"
    finishRun 1
}

close

