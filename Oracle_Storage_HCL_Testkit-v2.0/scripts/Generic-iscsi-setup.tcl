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

OVMlogin

set myServers [dict create]
set serverNames [discoverServers myServers]
set masterName [lindex $serverNames 0]
set slaveName [lindex $serverNames 1]

    
send_user "\n## [incr testStep 1]. Attempting to create the network $VM_Network for use with VMs\n"
createNetwork $VM_Network "VIRTUAL_MACHINE"

send_user "\n## [incr testStep 1]. Attempting to create the network $storageNetworkIP for use with storage\n"
createNetwork $storageNetworkIP "STORAGE"
setupNetworks $serverNames $myServers "True"


set myPluginID [findPlugin "False" "SCSI"]


send_user "\n## [incr testStep 1]. Discovering the SAN Server: '$SAN_ServerName'\n"
send "create StorageArray name='$SAN_ServerName' plugin=\"$myPluginID\" storageType=ISCSI accessHost=$SAN_AccessHost accessPort=$SAN_AccessPort\r"
validateCommandOutput "createSanServer command"

send_user "\nAdding $masterName and $slaveName as admin servers for '$SAN_ServerName'.\n"
send_user "\n## [incr testStep 1].  Adding $masterName as admin server for '$SAN_ServerName'\n"
send "addAdminServer StorageArray name='$SAN_ServerName' server=$masterName\r"
validateCommandOutput "addAdminServer command"

send_user "\n## [incr testStep 1].  Adding $slaveName as admin server for '$SAN_ServerName'\n"
send "addAdminServer StorageArray name='$SAN_ServerName' server=$slaveName\r"
validateCommandOutput "addAdminServer command"

set myAccessGroup [findAccessGroups]
addInitiators [dict get $myServers $masterName iscsi] $masterName $myAccessGroup
addInitiators [dict get $myServers $slaveName iscsi] $slaveName $myAccessGroup

send_user "\n## [incr testStep 1]. Validating the SAN Server: '$SAN_ServerName'\n"
send "validate StorageArray name='$SAN_ServerName'\r"
validateCommandOutput "validate StorageArray command"

send_user "\n## [incr testStep 1]. Refreshing the SAN Server: '$SAN_ServerName'\n"
send "refresh StorageArray name='$SAN_ServerName'\r"
validateCommandOutput "refresh StorageArray command"
   
close
