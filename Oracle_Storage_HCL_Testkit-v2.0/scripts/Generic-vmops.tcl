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
set testStep 0

send_user "\n## [incr testStep 1]. Importing $virtualCDROM_URL.  This will take several minutes...\n"
set isoID [importInstallMedia $repoName $virtualCDROM_URL "iso"]
if {$isoID == "False"} {
    send_user "Unable to read the ID of the VirtualCDROM which was just imported.\n"
    send_user "This will prevent all use of the ISO image for VMs and Clones.\n"
    send_user "Terminating.\n"
    finishRun 1
} 

send_user "\n## [incr testStep 1]. Importing $vmTemplateURL.  This will take several minutes...\n"
set templateID [importInstallMedia $repoName $vmTemplateURL "template"]
if {$templateID == "False"} {
    send_user "Unable to read the ID of the Template which was just imported.\n"
    send_user "This will prevent all use of the Template for VMs and Clones.\n"
    send_user "Terminating.\n"
    finishRun 1
} 

send_user "\n## [incr testStep 1]. Importing $vmAssemblyURL.  This will take several minutes...\n"
set assemblyID [importInstallMedia $repoName $vmAssemblyURL "assembly"]
if {$assemblyID == "False"} {
    send_user "Unable to read the ID of the Assembly which was just imported.\n"
    send_user "This will prevent all use of the Assembly for VMs and Clones.\n"
    send_user "Terminating.\n"
    finishRun 1
} 

send_user "\n## [incr testStep 1]. Finding the AssemblyVm ID for the Assembly.\n"
set myAssembyVMID [findAssemblyVMID $assemblyID]
if {$myAssembyVMID == "False"} {
    send_user "Unable to find the AssemblyVM associated with the Assembly\n"
    send_user "which was just imported.  This will prevent all use of the\n"
    send_user "assembly for VMs and Clones.\nTerminating.\n"
    finishRun 1
}

send_user "\n## [incr testStep 1]. Creating a VM from the Assembly: $myAssembyVMID\n"
set vmFromAssemblyID [createVMFromAssembly $myAssembyVMID]
if {$vmFromAssemblyID == "False"} {
    send_user "Unable to find ID for newly created VM.  This will prevent\n"
    send_user "the use of the newly created VM.\nTerminating.\n"
    finishRun 1
}


send_user "\n## [incr testStep 1]. Editing the memory and memoryLimit values for the newly created VM: $vmFromAssemblyID\n"
send -h "edit VM id=$vmFromAssemblyID memory=512 memoryLimit=512\r"
validateCommandOutput "edit VM command"

send_user "\n## [incr testStep 1]. Creating the VM: cloning $vmName2 from the VM: $vmFromAssemblyID\n"
send -h "clone VM id=$vmFromAssemblyID destType=Vm destName=$vmName2 serverPool=$serverPoolName\r"
validateCommandOutput "clone VM command"

send_user "\n## [incr testStep 1]. Editing the memory and memoryLimit values for the Template: $templateID\n"
send -h "edit VM id=$templateID memory=512 memoryLimit=512\r"
validateCommandOutput "edit VM command"

send_user "\n## [incr testStep 1]. Creating the VM: cloning $vmName1 from the Template: $templateID\n"
send -h "clone VM id=$templateID destType=Vm destName=$vmName1 serverPool=$serverPoolName\r"
validateCommandOutput "clone VM from template command"

send_user "\n## [incr testStep 1]. Creating a virtual disk for use by the VM: $vmName1\n"
send -h "create virtualDisk size=10 shareable=no sparse=yes name=$vdiskName1 on repository name=$repoName\r"
validateCommandOutput "create virtualDisk command"

send_user "\n## [incr testStep 1]. Mapping the virtual disk to $vmName2\n"
send -h "create vmDiskMapping slot=2 virtualDisk=$vdiskName1 name=vdiskMap1 on Vm name=$vmName2\r"
validateCommandOutput "create vmDiskMapping command"

send_user "\n## [incr testStep 1]. Mapping $sharedDiskID to $vmName1\n"
send -h "create vmDiskMapping slot=2 physicalDisk=$sharedDiskID name=lunMap1 on Vm name=$vmName1\r"
validateCommandOutput "create vmDiskMapping command"

send_user "\nAdding all vNICs to the VM Network: $VM_Network\n"
addVNICtoNetwork $VM_Network

send_user "\n## [incr testStep 1]. Starting $vmName1\n"
send -h  "start VM name=$vmName1\r"
validateCommandOutput "start vm command"

send_user "\n## [incr testStep 1]. Starting $vmName2\n"
send -h "start VM name=$vmName2\r"
validateCommandOutput "start vm command"


