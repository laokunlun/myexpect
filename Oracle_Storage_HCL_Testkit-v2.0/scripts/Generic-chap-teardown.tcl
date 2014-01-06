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

##################################################################
##
##       Test Suite 1: iSCSI with Generic Plugin with CHAP
##
##################################################################
##
##      +-----+-------+---------------+---------------+----------+
##      | LUN | Size  | OVM Server #1 | OVM Server #2 |   CHAP   |
##      +-----+-------+---------------+---------------+----------+
##      |  1  |  7 GB |               |               | Enabled  |
##      |  2  | 12 GB |               |               | Enabled  |
##      +-----+-------+---------------+---------------+----------+


OVMlogin
set testStep 0
send_user "\n\nDeleting the SAN Server '$SAN_ServerName'\n"
set status [deleteSANServer]
switch -- $status \
    "False" {
	finishRun 1
    } "None" {
	send_verbose "\nCould not find '$SAN_ServerName'! Deleting was unsuccesful!\nTerminating.\n"
	finishRun 1
    } "True" {
	send_verbose "\nSuccessfully deleted SAN Server: '$SAN_ServerName'.\nContinuing.\n\n"
    } default {
	send_user "An unexpected error has occurred."
	finishRun 1
    }




