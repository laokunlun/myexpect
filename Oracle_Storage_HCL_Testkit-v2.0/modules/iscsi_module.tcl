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


########## externally defined variables ############

set requiredParams_NonCHAP {ovmUser
    adminServer
    ovmServerMasterIP
    ovmServerSlaveIP
    serverPoolIP
    VM_Network
    VM_Netmask
    VM_NetworkPort
    virtualCDROM_URL 
    vmTemplateURL 
    vmAssemblyURL 
    ovmServerMaster_vmnetworkIP
    ovmServerSlave_vmnetworkIP
    SAN_ServerName
    SAN_AccessHost
    SAN_AccessPort
    storageNetworkIP
    storageNetworkPort
    storageNetworkNetmask
    ovmServerMaster_storageIP
    ovmServerSlave_storageIP}

set requiredParams_CHAP {ovmUser
    adminServer
    ovmServerMasterIP
    ovmServerSlaveIP
    serverPoolIP
    virtualCDROM_URL 
    vmTemplateURL 
    vmAssemblyURL 
    VM_Network
    VM_Netmask
    VM_NetworkPort
    ovmServerMaster_vmnetworkIP
    ovmServerSlave_vmnetworkIP
    SAN_ServerName
    SAN_AccessHost
    SAN_AccessPort
    CHAP_SUPPORTED
    CHAP_UserName
    storageNetworkIP
    storageNetworkPort
    storageNetworkNetmask
    ovmServerMaster_storageIP
    ovmServerSlave_storageIP}

set requiredParams_Vendor {ovmUser 
    adminServer 
    ovmServerMasterIP 
    ovmServerSlaveIP 
    PluginPrivateData 
    serverPoolIP 
    virtualCDROM_URL 
    vmTemplateURL 
    vmAssemblyURL 
    VM_Network 
    VM_Netmask 
    VM_NetworkPort 
    ovmServerMaster_vmnetworkIP 
    ovmServerSlave_vmnetworkIP 
    SAN_ServerName 
    SAN_AccessHost 
    SAN_AccessPort 
    SAN_AdminHost 
    SAN_AdminUsername 
    SAN_VolumeGroup 
    storageNetworkIP 
    storageNetworkPort 
    storageNetworkNetmask 
    ovmServerMaster_storageIP 
    ovmServerSlave_storageIP}
