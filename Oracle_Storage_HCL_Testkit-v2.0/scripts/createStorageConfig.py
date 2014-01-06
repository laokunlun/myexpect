#!/usr/bin/python

##
##    The Oracle Storage HCL Testkit is a suite of tests for certifying
##    storage with Oracle VM (OVM).
##    Copyright (C) 2013 Oracle USA, Inc 
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

import sys
import time
import re
import os
import optparse
import subprocess
import atexit
import ConfigParser
from modules import hclhelper


timestamp = time.strftime("%H%M%S-%m%d%Y", time.localtime())
mydate = time.strftime("%m%d%H%M", time.localtime())
logroot = '/tmp/OVM_HCL/'
logdir = logroot + timestamp + '/'
tempconfig = logdir + 'ovm-hcl-config.cfg'

def generateConfig(tempconfig, fc, iscsi, nfs, plugin):

    certInfo = [
        'Vendor',
        'Product_Name',
        'Model_Number',
        'Oracle VM Version',
        ]

    hostInfo = [
        'adminServer',
        'ovmUser',
        'ovmServerMasterIP',
        'ovmServerSlaveIP'
        ]

    serverPool = [
        'serverPoolIP',
        'VM_Network',
        'VM_Netmask',
        'VM_NetworkPort',
        'ovmServerMaster_vmnetworkIP',
        'ovmServerSlave_vmnetworkIP'
        ]
    
    installMedia = [
        'virtualCDROM_URL',
        'vmTemplateURL',
        'vmAssemblyURL',
        ]

    basicSAN = [
        'SAN_ServerName',
        'SAN_AccessHost',
        'storageNetworkIP',
        'storageNetworkNetmask',
        'storageNetworkPort',
        'ovmServerMaster_storageIP',
        'ovmServerSlave_storageIP',
        ]
                

    iscsiInfo = [
        'SAN_AccessPort',
        'CHAP_UserName',
        ]

    vendorPlugin = [
        'SAN_AdminHost',
        'SAN_AdminUsername',
        'SAN_VolumeGroup',
        'PluginPrivateData',
        ]
                   

    nfsInfo = [
        'NFS_IPAddress',
        'NFS_ServerName',
        'NFS_FilesystemName1',
        'NFS_FilesystemName2',
        'NFS_SharePath1',
        'NFS_SharePath2',
        ]
    

    basicInfo = {
        'Vendor': 'Enter the Vendor name, as it should appear on the Oracle HCL site: ',
        'Product_Name': 'Enter the exact storage array product name, as it should appear on the Oracle HCL site: ',
        'Model_Number': 'Enter the Model Numbers that fall under this certification (if applicable): ',
        'Oracle VM Version': 'Enter the Oracle VM Version against which this storage array is being certified [3.3]: ',
        'adminServer': 'Enter the IP address for the OVM Manager (OVMM): ',
        'ovmUser': 'Enter the Oracle VM Administrator username [admin]: ',
        'ovmServerMasterIP': 'Enter the IP address for the first Oracle VM Server (OVS): ',
        'ovmServerSlaveIP': 'Enter the IP address for the second Oracle VM Server (OVS): ',
        'serverPoolIP': 'Enter the Virtual IP Address for the Server Pool: ',
        'serverPort': 'Enter the ethernet port which should be used for the Virtual Machine: ',
        'SAN_ServerName': 'Enter a name to identify the SAN server: ',
        'SAN_AdminHost': 'Enter the IP address where administrative access to the SAN server is allowed: ',
        'SAN_AdminUsername': 'Enter the user name with administrative access to the SAN server: ',
        'SAN_AccessHost': 'Enter the IP address for the SAN server: ',
        'SAN_AccessPort': 'Enter the port on which access to the SAN server is allowed [3260]: ',
        'storageNetworkIP': 'Enter the IP subnet for the storage network: ',
        'storageNetworkPort': 'Enter the Ethernet port or Bond port on the OVS Servers which should should be configured for the Storage Network: ',
        'ovmServerMaster_storageIP':'Enter the IP address on the Storage Network for the first OVS Server: ',
        'ovmServerSlave_storageIP': 'Enter the IP address on the Storage Network for the Second OVS Server: ',
        'VM_Netmask': 'Enter the netmask to use for the VM Network: ',
        'VM_Network': 'Enter the IP subnet for the VM Network: ',
        'VM_NetworkPort': 'Enter the Ethernet or Bond port on the OVS servers which should be configured for the VM Network: ',
        'ovmServerMaster_vmnetworkIP': 'Enter the IP address on the VM Network for the first OVS Server: ',
        'ovmServerSlave_vmnetworkIP': 'Enter the IP address on the VM Network for the Second OVS Server: ',
        'storageNetworkNetmask': 'Enter the netmask to use for the Storage Network: ',
        'SAN_VolumeGroup': 'Enter the Volume Group on which to create LUNs: ',
        'PluginPrivateData': 'Enter the information for the Plugin Private Data field,\nin the exact format which it is expected by the Plugin: ',
        'CHAP_UserName': 'Enter the CHAP User Name: ',
        'virtualCDROM_URL': 'Enter the URL from where the iso DVD or CDROM can be downloaded: ',
        'vmTemplateURL': 'Enter the URL from where the VM Template can be downloaded: ',
        'vmAssemblyURL': 'Enter the URL from where the VM Assembly can be downloaded: ',
        'NFS_IPAddress': 'Enter the IP address for the NFS File Server: ',
        'NFS_ServerName': 'Enter the Name of the NFS File Server: ',
        'NFS_FilesystemName1': 'Enter the name first exported filesystem: ',
        'NFS_FilesystemName2': 'Enter the name of the second exported filesystem:  ',
        'NFS_SharePath1': 'Enter the name of the first Share Path (i.e. \'repo1\'): ',
        'NFS_SharePath2': 'Enter the name of the first Share Path (i.e. \'repo2\'): ',
        }

    output = None

    try:
        output = open(tempconfig, 'w')
    
        print "Generating configuration file: " + tempconfig + "...."
        print "Passwords are not stored in the Config file, and will be prompted for at runtime."
        
        output.write("#############################################\n")
        output.write("###       Certification Information       ###\n")
        output.write("#############################################\n")

        print "\n\nGathering information about the Storage Array being certified."
        print "================================================================"
        for key in certInfo:
            reply = raw_input(basicInfo[key])

            if key == "Oracle VM Version" and reply == "":
                reply = "3.3"

            output.write(key + ': ' + reply + '\n')

            if key == "Product_Name":
                more = True

                while more:
                    reply = raw_input("Enter another Product Name? (y|n): ")
                    if reply == 'y' or reply == 'Y':
                        reply = raw_input(basicInfo[key])
                        output.write(key + ': ' + reply + '\n')
                    if reply == 'n' or reply == 'N':
                        more = False


        output.write("\n")
        output.write("#############################################\n")
        output.write("###              OVM settings             ###\n")
        output.write("#############################################\n")
        print "\n\nGathering basic OVM manager and server information..."
        print "====================================================="
        for key in hostInfo:
            reply = raw_input(basicInfo[key])

            if key == 'ovmUser' and reply == "":
                reply = 'admin'

            output.write(key + '=' + reply + '\n')
            
        output.write("\n\n#############################################\n")
        output.write("###         Server Pool settings          ###\n")
        output.write("#############################################\n")
        print "\n\nGathering Server Pool settings..."
        print "====================================================="
        for key in serverPool:
            reply = raw_input(basicInfo[key])

            if key == "VM_Network":
                network = reply

            if key == "VM_Netmask":
                netmask = reply

            output.write(key + '=' + reply + '\n')

            
        output.write("\n\n#############################################\n")
        output.write("###             Install Media             ###\n")
        output.write("#############################################\n")
        print "\n\nGathering VM OS Install Media information..."
        print "====================================================="
        for key in installMedia:
            reply = raw_input(basicInfo[key])
            output.write(key + '=' + reply + '\n')


        if iscsi or (fc and plugin):
    
            output.write("\n\n#############################################\n")
            output.write("###           SAN Server Info             ###\n")
            output.write("#############################################\n")
            print "\n\nGathering required SAN Server settings..."
            print "====================================================="
            for key in basicSAN:
                reply = raw_input(basicInfo[key])
                
                if key == "storageNetworkIP" and reply == "":
                    reply = network

                if key == "storageNetworkNetmask" and reply == "":
                    reply = netmask

                output.write(key + '=' + reply + '\n')


        if iscsi:
            print "\n\nGathering iSCSI specific information..."
            print "====================================================="
            for key in iscsiInfo:
            
                if key == "CHAP_UserName":
                    ask_support = True
                    chap_support = False
                    while ask_support:
                        reply = raw_input("Is CHAP Authentication supported? (yes|no) ")
                        if reply == "yes" or reply == "y":
                            output.write("CHAP_Support=SUPPORTED\n")
                            reply = raw_input(basicInfo[key])
                            chap_support = True
                            ask_support = False
                        elif reply == "no" or reply == "n":
                            output.write("CHAP_Support=UNSUPPORTED\n")
                            ask_support = False
                        else:
                            print "Please answer yes or no."
                    
                else:
                    reply = raw_input(basicInfo[key])

                if key == "SAN_AccessPort" and reply == "":
                    reply = "3260"
                    
                if key == "CHAP_UserName" and not chap_support:
                    continue

                output.write(key + '=' + reply + '\n')

                
        if plugin and (fc or iscsi):
            print "\n\nGathering Vendor Supplied Plugin settings"
            print "====================================================="
            for key in vendorPlugin:
                if key == "PluginPrivateData":
                    ask_pd = True
                    pdata = False
                    while ask_pd:
                        reply = raw_input("Does the Plugin require extra data to be set in the Private Data field? (yes|no) ")
                        if reply == "yes" or reply == "y":
                            output.write('PrivateDataSupported=SUPPORTED\n')
                            reply = raw_input(basicInfo[key])
                            pdata = True
                            ask_pd = False
                        elif reply == "no" or reply == "n":
                            output.write('PrivateDataSupported=UNSUPPORTED\n')
                            pdata = False
                            ask_pd = False
                        else:
                            print "Please answer yes or no."
                else:
                    reply = raw_input(basicInfo[key])

                if key == "PluginPrivateData" and not pdata:
                    continue
                    
                output.write(key + '=' + reply + '\n')

        if nfs:

            output.write("\n\n#############################################\n")
            output.write("###          NFS File Server Info         ###\n")
            output.write("#############################################\n")
            print "\n\nGathering NAS/NFS File Server settings ..."
            print "====================================================="
            for key in nfsInfo:
                reply = raw_input(basicInfo[key])
                
                output.write(key + '=' + reply + '\n')

    finally:
       if output != None:
           output.close()

    print "\n\nThe new configuration file has been written to: " + tempconfig
    return
    
def getOptions():
        
    print "Storage HCL Configuration File Generator"
    print "---------------------------------------------------------\n"
    print "Please select whether to create a configuration file for"
    print "all protocols (FibreChannel, iSCSI, and NFS) and plugins,"
    print "or to specify protocols.\n"
    reply = raw_input("Create a configuration file for all protocols? (yes|no) ")

    if reply == "y" or reply == "Y" or reply == "yes":
        return True, True, True, True


    opts = {'FibreChannel': False,
                   'iSCSI': False,
                   'NFS': False,
                   'Vendor Plugin': False}

    for key in opts:
        reprompt = True
        while reprompt:
            reply = raw_input("Include "+key+" options in config file? (yes|no) ")
            if reply == "y" or reply == "Y" or reply == "yes":
                opts[key] = True
                reprompt = False
            elif reply == "n" or reply == "N" or reply == "no":
                opts[key] = False
                reprompt = False
            else:
                print "Please answer yes or no"

    return opts['FibreChannel'], opts['iSCSI'], opts['NFS'], opts['Vendor Plugin']



def main():

    status = False
    
    fc, iscsi, nfs, vendorPlugin = getOptions()

    try:
        if not os.path.exists(logdir):
            os.makedirs(logdir)
        generateConfig(tempconfig, fc, iscsi, nfs, vendorPlugin)

    except OSError, e:
        print >>sys.stderr, "Execution failed:", e
        print "Unable to create logging directory: " + logdir
        print "Exiting...."
        sys.exit(2)

    except (hclhelper.HCLERROR) as err:
        print "\n\nError: "+err.value
        print "Exiting...."
        sys.exit(2)

    
    exit


if __name__ == "__main__":
    try:
        main()
    except (KeyboardInterrupt):
        print "\n\nCaught user requested termination.  Exiting."
        sys.exit(2)
    except (IOError,OSError) as err:
        print "\n\nCaught exception: "+err
        sys.exit(2)
