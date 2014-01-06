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
##      +-----+-------+-------+---------------+---------------+
##      | LUN |  Old  |  New  | OVM Server #1 | OVM Server #2 |
##      +-----+-------+-------+---------------+---------------+
##      |  1  |  5 GB |  7 GB |       X       |       X       |
##      |  2  | 10 GB | 12 GB |       X       |       X       |
##      +-----+-------+-------+---------------+---------------+

OVMlogin
set teststep 0

foreach lun $lunList {
    dict set lunInfo $lun size [getDiskSize $lun]
}

refreshLUNs $is_iscsi $lunList $serverNames $myServers

set sizelist {7 12}
if {[verifyResize $lunList $sizelist lunInfo] == "False"} {
    finishRun 1
} else {
    send_user "The LUNs have been correctly resized.\n"
}

close
