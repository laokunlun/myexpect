
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
import os.path
import time
import re
import subprocess
import shutil
import getpass

VERBOSE = False

## For pretty printing.  We want to have visual cues
## for test failures, successes and warnings.
class Colors:
    HEADER = '\033[36m'
    OK = '\033[1m'
    PASS = '\033[92m'
    WARNING = '\033[93m'
    FAIL = '\033[91m'
    ENDC = '\033[0m'

## Essentially implement tee so that we can have
## output written to both the screen and log files
class Logger(object):

    def __init__(self, stdout, filename):
        self.stdout = stdout
        self.logfile = open(filename, 'a')

    def __del__(self):
        sys.stdout.close()
        sys.stdout = self.stdout
        self.logfile.close()

    def write(self, text):
        self.stdout.write(text)
        self.logfile.write(text)

    def close(self):
        sys.stdout = self.stdout
        self.logfile.close()


## Prompt for passwords since we don't really want
## to keep them around and visible once the tests
## complete.
def getPassWD(userString):
    
    try:
        mismatch = True

        while mismatch:
            passwd1 = getpass.getpass("HCL> Enter the "+userString+" password: ")
            if passwd1 == "":
                print "Password cannot be blank!"                
                continue

            passwd2 = getpass.getpass("HCL> Enter the "+userString+" password (confirm): ")

            if passwd1 == passwd2:
                mismatch = False
            else:
                print "Passwords do not match!"            
                
                
    except (KeyboardInterrupt, SystemExit):
        print "\n\nCaught user requested termination.  Exiting."
        os.system("stty sane")
        sys.exit(2)
        
    return passwd1
    

def kickOff(config, testSuite, logdir, ovmPWD, ovmAgent, chap):

    needToBail = False
    
    print "\n\n"
    print Colors.HEADER+"--------------------------------------------------------------------------"
    print "Beginning output for "+testSuite
    print "--------------------------------------------------------------------------\n\n"+Colors.ENDC
    
    templateFileExitCode, expectFileString = writeExecutionFile(config, testSuite, logdir)
    if not templateFileExitCode:
        needToBail = True
        
    if needToBail:
        exitCode = False
        timelapse = 0
    else:
        exitCode, timelapse = runCert(testSuite, logdir, expectFileString, ovmPWD, ovmAgent, chap)

    print "\n"
    if exitCode:
        print Colors.OK+testSuite+": "+Colors.PASS+"PASSED\n"+Colors.ENDC
    else:
        print Colors.OK+testSuite+": "+Colors.FAIL+"FAILED\n"+Colors.ENDC
        print "\nUnexpected errors occurred during the execution of the certification tests"
        print "leaving the environment in an unknown state which will prevent all further"
        print "tests from executing cleanly.\nExiting.\n"
        needToBail = True
                
    print "Please view the logs in " + logdir + " for further details."
    print "\n\nExecution of " + testSuite + " completed after " + str(timelapse / 60) + "." + str(timelapse % 60) + " minutes."
    print "\n\n--------------------------------------------------------------------------"
    print "--------------------------------------------------------------------------\n\n"

    return needToBail,timelapse



def runCert(testname, logdir, expectFileString, ovmPassword, ovmAgent, haspswd):

    writeFile = None
    tempTestFile = "/tmp/" + testname + str(time.time()) + ".exp"
    
    try:
        writeFile = open(tempTestFile, "w")
        writeFile.write(expectFileString)

    finally:
        if writeFile != None:
            writeFile.close()
        else :
            print ("Unable to write runtime test file: %s." %(tempTestFile))
            print "Terminating."
            sys.exit(2)

    if VERBOSE:
        verbose = "1"
    else:
        verbose = "0"

    if haspswd == "UNSUPPORTED":
        myProc = "expect -f " + tempTestFile + " " + ovmPassword + " " + ovmAgent + " " + verbose
    else:
        myProc = "expect -f " + tempTestFile + " " + ovmPassword + " " + ovmAgent + " " + haspswd + " " + verbose

    startTime = time.time()
    expectScriptExitCode = None

    try:
        expectScriptExitCode = subprocess.call(myProc, shell=True)
    finally:
        endTime = time.time()
        os.remove(tempTestFile)

        if (expectScriptExitCode == 0):
            return True,int(endTime - startTime)
        else:
            return False,int(endTime - startTime)
        

## Read in the existing test script, so that we can substitute the
## user supplied values from the config file, into the script.
def parseExistingTest(filename):

    storeLine = ""

    try:
        for line in open(filename).readlines():
            storeLine = storeLine + line
        
    except:
        print "Fatal Error raised while reading "+filename+"!\nExiting."
        sys.exit(2)


    return (re.findall(r'\${.*?}', storeLine), storeLine)

## Parse the config file and match required argument values with the
## user supplied values from the config file.  Re-write a new and 
## temporary executable that will be used for the test run.
def writeExecutionFile(config, testname, logdir):
    replacementValues = {}
    missingValues = []
    index = 0

    replacementValues['${hcllogdir}'] = logdir

    ## Read the config file line by line, gathering all of 
    ## the user defined values for the required parameters.  
    ## Ignore any line that doesn't match the x=y pattern.
    try:
        for line in open(config).readlines():
            if (re.match(r'^\#.*?$', line)):
                continue
            elif (re.match(r'^\s*\n', line)):
                continue
            elif (re.match(r'.+?\: ', line)):
                continue
            
            myArgVal = line.split("=", 1)
            myValue = myArgVal[1].strip();
            replacementValues['${' + myArgVal[0].strip() + '}'] = myValue
            
    except:
        print "Fatal error raised while reading "+config+"!\nExiting."
        return (False, None)

    ## Now read the test file looking for the lines
    ## where the required parameters need to be
    ## defined.  
    requiredArgs, storeLine = parseExistingTest(testname)
    myKeys = replacementValues.keys()

    ## Make sure that every required parameter has been
    ## defined in the config file.  We don't want to 
    ## start executing the test if we're missing any
    ## required user defined information.
    for arg in requiredArgs:
        if (arg not in myKeys):
            missingValues.append(arg)
        else:
            if (replacementValues[arg] == ""):
                missingValues.append(arg)
        

    if (len(missingValues) > 0):
        print Colors.WARNING + "The following parameters are required to run the " + testname + " script"
        print "but they have not been set in " + config + ":\n"
        for x in missingValues:
            print ("%s" % (x[2:-1]))
        print "\nPlease edit " + config
        print "and kick off the certification run again." + Colors.ENDC
        return (False, None) 
    
    ## Replace the generic value from the original test script
    ## with the user defined values.  We'll write this out to 
    ## a temporary test file that will be deleted when the 
    ## test completes.
    for key in replacementValues:
        storeLine = storeLine.replace(key, replacementValues[key])


    print_verbose ("INFO   : Required arguments and values:") 
    for x in requiredArgs:
        if (x.lower().find("password") == -1):
            print_verbose ("INFO   :    %s=%s" %(x[2:-1], replacementValues[x]))
        else:
            print_verbose ("INFO   :    %s=%s" %(x[2:-1], "xxxxxxxx"))

    return (True, storeLine)


## Package up the log files into a tarfile for easy transport
def packageLogs(logroot, logdir, timestamp):

    ## Cleanup the log files first
    logCleanse(logdir)
    
    myTGZ = logroot + "ovm-storage-hcl_" + str(timestamp) + ".tgz"
    try:
        r = subprocess.Popen(["tar", "czf", myTGZ, logdir], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    except:
        print "Unable to package " + logdir + " into " + myTGZ + ".\nExiting.\n" 
        sys.exit(2)



###  Generate a config file based on user input.  
###  Give the user an opportunity to quit and then
###  edit the file if they need to before running the
###  tests.
def generateConfig(tempconfig):

    certInfo = [
        'Vendor',
        'Product_Name',
        'Model_Number',
        'Oracle VM Version',
        ]

    hostInfo = [
        'adminServer',
        'ovmUser',
        'ovmAgentUsername',
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
        'Oracle VM Version': 'Enter the Oracle VM Version against which this storage array is being certified [3.2.1]: ',
        'adminServer': 'Enter the IP address for the OVM Manager (OVMM): ',
        'ovmUser': 'Enter the Oracle VM Administrator username [admin]: ',
        'ovmAgentUsername': 'Enter the Oracle VM Agent Username [oracle]: ',
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
        'storageNetworkPort': 'Enter the Ethernet port on the OVS Servers which should should be configured for the Storage Network [eth1]: ',
        'ovmServerMaster_storageIP':'Enter the IP address on the Storage Network for the first OVS Server: ',
        'ovmServerSlave_storageIP': 'Enter the IP address on the Storage Network for the Second OVS Server: ',
        'VM_Netmask': 'Enter the netmask to use for the VM Network: ',
        'VM_Network': 'Enter the IP subnet for the VM Network: ',
        'VM_NetworkPort': 'Enter the Ethernet port on the OVS servers which should be configured for the VM Network [eth0]: ',
        'ovmServerMaster_vmnetworkIP': 'Enter the IP address on the VM Network for the first OVS Server: ',
        'ovmServerSlave_vmnetworkIP': 'Enter the IP address on the VM Network for the Second OVS Server: ',
        'storageNetworkNetmask': 'Enter the netmask to use for the Storage Network: ',
        'SAN_VolumeGroup': 'Enter the Volume Group on which to create LUNs (for Vendor Specific plugin cert only): ',
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
                reply = "3.2.1"

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

            if key == 'ovmAgentUsername' and reply == "":
                reply = 'oracle'

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

            if key == "VM_NetworkPort" and reply == "":
                reply = "eth0"
                

            output.write(key + '=' + reply + '\n')

            
        output.write("\n\n#############################################\n")
        output.write("###             Install Media             ###\n")
        output.write("#############################################\n")
        print "\n\nGathering VM OS Install Media information..."
        print "====================================================="
        for key in installMedia:
            reply = raw_input(basicInfo[key])
            output.write(key + '=' + reply + '\n')
    
        output.write("\n\n#############################################\n")
        output.write("###           SAN Server Info             ###\n")
        output.write("#############################################\n")
        print "\n\nGathering required SAN Server settings..."
        print "====================================================="
        for key in basicSAN:
            reply = raw_input(basicInfo[key])

            if key == "SAN_ServerName" and reply == "":
                reply = "undefined"

            if key == "storageNetworkIP" and reply == "":
                reply = network

            if key == "storageNetworkNetmask" and reply == "":
                reply = netmask

            if key == "storageNetworkPort" and reply == "":
                reply = "eth1"

            output.write(key + '=' + reply + '\n')

        print "\n\nGathering iSCSI specific information..."
        print "====================================================="
        for key in iscsiInfo:
            
            if key == "CHAP_UserName":
                reply = raw_input("Is CHAP Authentication supported? [yes|no] ")
                if reply == "yes":
                    reply = raw_input(basicInfo[key])
                else:
                    reply = "UNSUPPORTED"
                    
            else:
                reply = raw_input(basicInfo[key])

            if key == "SAN_AccessPort" and reply == "":
                reply = "3260"

            if key == "CHAP_UserName" and reply == "":
                reply = "UNSUPPORTED"

            output.write(key + '=' + reply + '\n')

        print "\n\nGathering Vendor Supplied Plugin settings"
        print "====================================================="
        for key in vendorPlugin:
            reply = raw_input(basicInfo[key])
            output.write(key + '=' + reply + '\n')



        output.write("\n\n#############################################\n")
        output.write("###          NFS File Server Info         ###\n")
        output.write("#############################################\n")
        print "\n\nGathering NAS/NFS File Server settings ..."
        print "====================================================="
        for key in nfsInfo:
            reply = raw_input(basicInfo[key])

            if key == "NFS_ServerName" and reply == "":
                reply = "undefined"

            output.write(key + '=' + reply + '\n')

    finally:
       if output != None:
           output.close()

    print "\n\nThe new configuration file has been written to: " + tempconfig
    print "If you need to make any corrections to the information you entered,"
    print "simply press enter at the prompt to quit the script so that you can"
    print "edit the config file.  Once you've made changes to the config file,"
    print "rerun this script and use the --config option to specify the full"
    print "path to your edited version of the config file.\n"
    print "If you are satisfied with the information you entered, type begin at"
    print "the prompt to continue.\n"

    reply = raw_input("HCL> ")
    if (reply != "begin"):
        sys.exit(0)
    
## Make sure the config file exists and is really a file.
## Once we establish that, more checking can be done.
def verifyConfig(config, logdir):

    verify = True
    
    if not os.path.exists(config):
        verify = False
        print "\n"+Colors.WARNING + config + " does not exist!\n"+Colors.ENDC
    elif not os.path.isfile(config):
        verify = False
        print "\n"+Colors.WARNING + config + " is not a file!\n"+Colors.ENDC

    if not verify:
        print "Please re-run the script without the --config option set"
        print "to generate a new config file, or with the --config option"
        print "set and the full path to an existing config file."
        return verify

    configname = getFileName(config)
    tmpconfig = logdir + configname + ".copy"

    ## The file exists, and is readable, so now make a copy in the 
    ## logging directory for future reference.
    shutil.copyfile(config, tmpconfig)

    ## and verify that the copy worked....
    if not os.path.exists(tmpconfig):
        verify = False
        print "\n"+Colors.WARNING + config + " could not be copied to" + tmpconfig + "!\n"+Colors.ENDC
    elif not os.path.isfile(tmpconfig):
        verify = False
        print "\n"+Colors.WARNING + config + " could not be copied to" + tmpconfig + "!\n"+Colors.ENDC

    if not verify:
        print "Could not successfully copy " + config + "to "+tmpconfig+".\nTerminating."

    return verify


def getFileName(pathname):
    
    parts = pathname.split('/')
    length = len(parts)
    
    if parts[length - 1] == '':
        return parts[length - 2]
    else:
        return parts[length - 1]


## The log files will contain passwords because OVM echoes back
## every command to the screen, and this output is captured in
## the log files.  We need to scrub the logs to remove all of the
## passwords that have been captured.
def logCleanse(logdir):

    fail = False
    openlog = False
    wrapperlog = logdir + "Certification_Results.log"
    mycwd = os.getcwd()

    ## There may be other files in the log directory, but
    ## they are unlikely to contain password information
    ## that will match the patterns we're searching for
    ## so only run the script against the files we know
    ## are going to have passwd info.
    pattern = re.compile(r".*\.log")
    pattern2 = re.compile(r".*Certification_Results\.log")
    
    for myfile in os.listdir(logdir):
        if pattern.match(myfile):
                
            ## If we find the wrapper log, it's still open and being
            ## written to, so we need deal with that.  Closing the
            ## file stream closes the file and redirects stdout back 
            ## to sys.stdout 
            if pattern2.match(myfile):
                savelogger = sys.stdout
                savelogger.close()
                openlog = True


            ## parse the logfile and write everything back out to 
            ## a temporary file,
            try:
                logfile = open(logdir+myfile, 'r')
                tmplog = open(logdir+myfile+'.tmp', 'w')
                line = logfile.readline()

                while line:
                    passwd1 = re.match('.+?([Pp]assword=)(.+?\s)',line)
                    passwd2 = re.match('.+? (password.*?)(:.+?)$',line)

                    if passwd1:
                        line = line.replace(passwd1.group(2),'xxxxxxx ')
                    if passwd2:                    
                        line = line.replace(passwd2.group(2),': xxxxxxx')
                    
                    tmplog.write(line)
                    line = logfile.readline()

            finally:
                logfile.close()
                tmplog.close()

                tmpstats = os.stat(logdir+myfile+".tmp")
        
                ## If the temp file couldn't be written, it will be
                ## empty, so we can just delete it.
                if tmpstats.st_size > 0:
                    os.rename(logdir+myfile+".tmp",logdir+myfile)
                else:
                    os.remove(logdir+myfile+".tmp")
                    fail = True

                ## Since we closed the main wrapper log file, we need 
                ## to open it back up for writing again....
                if openlog:
                    logger = Logger(sys.stdout, wrapperlog)
                    sys.stdout = logger
                    openlog = False
                    

    if fail:
        fakename = "TestSuite2_FibreChannel.log"
        print Colors.WARNING+"\nOVM echoes back each command that was entered, and all OVM commands"
        print "and output are captured in the logfiles.  This means that logfiles"
        print "will contain passwords in plain text.  An attempt has been made to" 
        print "purge all plain text passwords from the logfiles, but was unsuccessful" 
        print "for one or more of the logfiles in "+logdir+"."+Colors.ENDC



## Copy Admin logs, ovs agent logs, cli logs
## and sosreports from the servers.  Since we need
## to have comprehensible output, these operations
## are atomic.
def gatherServerLogs(timestamp, logdir, config):

    bailout = False

    nodes = {'manager':{}, 'master':{}, 'slave':{}}

    nodes['manager']['isManager'] = True
    nodes['master']['isManager'] = False
    nodes['slave']['isManager'] = False

    nodes['manager']['name'],nodes['master']['name'],nodes['slave']['name'] = getServers(config)
    nodes['manager']['password'],nodes['master']['password'],nodes['slave']['password'],bailout = passwdQuery(nodes['manager']['name'],nodes['master']['name'],nodes['slave']['name'])

    
    ### It's possible that someone doesn't want to enter the root passwords into
    ### the scripts, so we've given them the option to bail out without going
    ### through the proces of gathering the required logs for them.
    if bailout:
        print "\nGathering logs and sosreports has been skipped by the user."
        print "If you would like to gather the logs and sosreports automatically"
        print "at another time, please re-run the script with the -g option"
        print "selected.\n"
        return
    

    if VERBOSE:
        verbose = "1"
    else:
        verbose = "0"
        
        
    ### The actual script for copying the logs over is an Expect
    ### script called "GetLogs".  Depending on how it's invoked
    ### the script will copy OVM Admin and CLI logs, or will copy
    ### ovs-agent logs and sosreport.  The script will login to 
    ### the ovs servers and run sosreport and then copy the
    ### report .bzp file to the log directory
    for machine in nodes:
        if nodes[machine]['isManager']:
            isManager = "True"
        else:
            isManager = "False"

        myString = "expect -f GetLogs " +nodes[machine]['name']+" "+nodes[machine]['password']+" "+logdir+" "+timestamp+" "+verbose+" "+isManager

        try:
            expectScriptExitCode = subprocess.call(myString, shell=True)
        finally:
            endTime = time.time()

        if (expectScriptExitCode != 0):
            print "\nErrors occured while copying logs from "+nodes[machine]['name']
            print "Please view the logfile named Copy_Logs-"+nodes[machine]['name']+".log"
            print "for additional details"



        

## Parse the config file looking for manager, and two ovs nodes.
## This function is used when gathering logs after the tests
## have completed.
def getServers(config):
    server1 = ""
    server2 = ""
    manager = ""

    readconfig = open(config, 'r')

    try:
        for line in readconfig:
            if line.startswith('adminServer'):
                val = line.split("=", 1)
                manager = val[1].strip()
            elif line.startswith('ovmServerMasterIP'):
                val = line.split("=", 1)
                server1 = val[1].strip()
            elif line.startswith('ovmServerSlaveIP'):
                val = line.split("=", 1)
                server2 = val[1].strip()

    finally:
        readconfig.close()
       
    return manager,server1,server2


## Gather passwords so that we can collect logfiles.
## the user is given the option to skip this step
## if they prefer to not enter root passwords.
## Without the passwords we cannot copy logs...
def passwdQuery(manager,server1,server2):
    
    pass1 = ""
    pass2 = ""
    pass3 = ""
    bail = False
    samepwd = False
    again = True
    
    print "\nAt this point in the certification tests, we will attempt"
    print "login to the OVM Manager and two OVS server nodes to gather"
    print "logs and sosreport output.  For this, you will need to enter"
    print "the root password for the three machines.  If you choose to"
    print "execute this step manually, enter \"skip\" at the prompt."
    print "Otherwise, answer yes or no."

    while again:
        
        pwdans = raw_input("\nHCL> Is the root password the same for all three machines? [yes|no|skip] ")

        if pwdans == "skip":
            bail = True
            again = False
        elif pwdans == "yes" or pwdans == "Yes":
            samepwd = True
            again = False
        elif pwdans == "no" or pwdans == "No":
            again = False
        else:
            print "Please type \'yes\', \'no\', or \'skip\'"

    if bail:
        return pass1,pass2,pass3,bail
    
    if samepwd:
        pass1 = pass2 = pass3 = getPassWD("root")
    else:
        pass1 = getPassWD("root@"+manager)
        pass2 = getPassWD("root@"+server1)
        pass3 = getPassWD("root@"+server2)

    return pass1,pass2,pass3,bail


def print_verbose(msg):

    global VERBOSE

    if VERBOSE:
        print msg



def getChap(config):

    chap = ""

    readconfig = open(config, 'r')

    try:
        for line in readconfig:
            if line.startswith('CHAP_UserName'):
                val = line.split("=", 1)
                chap = val[1].strip()
    finally:
        readconfig.close()

    if chap == "UNSUPPORTED":
        return chap
    else:
        return getPassWD("CHAP Admin User's")



def runGenericFC(config, logdir, ovmPassword, ovmAgent):

    failCount = 0
    passCount = 0
    totallapse = 0
    manager,master,second = getServers(config)

    testNames = {'fc_01': 'Test_Suite_1-FibreChannel_Setup',
                 'fc_02': 'Test_Suite_1-FibreChannel_Map1',
                 'fc_03': 'Test_Suite_1-FibreChannel_Resize',
                 'fc_04': 'Test_Suite_1-FibreChannel_Unmap',
                 'fc_05':'Test_Suite_1-FibreChannel_Map2',
                 'fc_06': 'Test_Suite_1-FibreChannel_Map3',
                 'fc_07': 'Test_Suite_1-FibreChannel_Repo'}

    testAssoc = {'fc_01': ['GSFC-101'],
                 'fc_02': ['GSFC-102'],
                 'fc_03': ['GSFC-103'],
                 'fc_04': ['GSFC-104'],
                 'fc_05': ['GSFC-105'],
                 'fc_06': ['GSFC-106'],
                 'fc_07': ['GSFC-107', 'GSFC-108']}
    
    testCaseStatus = {'GSFC-101': 'Not Run',
                      'GSFC-102': 'Not Run',
                      'GSFC-103': 'Not Run',
                      'GSFC-104': 'Not Run',
                      'GSFC-105': 'Not Run',
                      'GSFC-106': 'Not Run',
                      'GSFC-107': 'Not Run',
                      'GSFC-108': 'Not Run',
                      'GSFC-109': 'Manual Testcase',
                      'GSFC-110': 'Manual Testcase'}
        
    map1 = "\nHCL> At this time, please map a 5G LUN to " + master +", and then map\n     a 10G LUN to " + second + ".  After the LUNs have been\n     mapped, press Enter to resume: "

    testPrompt = {'fc_01': '',
                  'fc_02': map1,
                  'fc_03': '\nHCL> At this time, please resize the LUNs from the previous test.\n     Increase the LUN sizes to 7G and 12G, respectively.\n     After the LUNs have been resized, press Enter to resume: ',
                  'fc_04': '\nHCL> At this time, please unmap the 7G and 12G LUNs from the previous step.\n     After the LUNs have been unmapped, press Enter to resume: ',
                  'fc_05': '\nHCL> At this time, please map four new LUNs to both servers.\n     The LUNs must be the following sizes: 2G, 5G, 10G, and 30G.\n     After the LUNs have been mapped, press Enter to resume: ',
                  'fc_06': '\nHCL> At this time, unmap the 2GB LUN from both servers, grow\n     the 5G LUN to 15G, and grow the 10G LUN to 20G.  The 30G LUN\n     remains the same size.  These are the required LUN sizes for\n     the remainder of the tests.  After the LUNs have been unmapped\n     and resized accordingly, press Enter to resume: ', 
                  'fc_07': ''}
                  


    for key in sorted(testNames): 

        if not testPrompt[key] == '':
            reply = raw_input(testPrompt[key])
        
        status,timelapse = kickOff(config, testNames[key], logdir, ovmPassword, ovmAgent, "UNSUPPORTED")

        totallapse = totallapse + timelapse
        myList = testAssoc[key]
        
        if status:
            failCount = failCount + 1
            for testcase in myList:
                testCaseStatus[testcase] = "Failed"
            print "Test failures cause the environment to be in an unknown state, and therefore"
            print "the certification tests are unable to proceed at this time.  Please run the"
            print "cleanup scripts by specifying the -k option, and begin the certification run"
            print "again after all failures have been addressed.\n"
            break

        else:
            passCount = passCount + 1
            for testcase in myList:
                testCaseStatus[testcase] = "Passed"

    
    print "--------------------------------------------------------------------------"
    if failCount:
        runstatus = True
    else:
        runstatus = False
    print "Individual Test Case Results:"
    for key in sorted(testCaseStatus):
        print key + " ................................  "+testCaseStatus[key] 

    print "--------------------------------------------------------------------------"


    return runstatus,totallapse



def runGenericiSCSI(config, logdir, ovmPassword, ovmAgent, chap):

    failCount = 0
    passCount = 0
    totallapse = 0

    manager,master,second = getServers(config)

    testNames = {'iscsi_01': 'Test_Suite_1-iSCSI_CHAP_setup',
                 'iscsi_02': 'Test_Suite_1-iSCSI_CHAP_Map1',
                 'iscsi_03': 'Test_Suite_1-iSCSI_CHAP_Resize',
                 'iscsi_04': 'Test_Suite_1-iSCSI_CHAP_Unmap',
                 'iscsi_05': 'Test_Suite_1-iSCSI_Setup',
                 'iscsi_06': 'Test_Suite_1-iSCSI_Map1',
                 'iscsi_07': 'Test_Suite_1-iSCSI_Resize',
                 'iscsi_08': 'Test_Suite_1-iSCSI_Unmap',              
                 'iscsi_09': 'Test_Suite_1-iSCSI_Map2',
                 'iscsi_10': 'Test_Suite_1-iSCSI_Map3',
                 'iscsi_11': 'Test_Suite_1-iSCSI_Repo'}


    testCaseStatus = {'GSIS-101': 'Not Run',
                      'GSIS-201': 'Not Run',
                      'GSIS-202': 'Not Run',
                      'GSIS-203': 'Not Run',
                      'GSIS-204': 'Not Run',
                      'GSIS-301': 'Not Run',
                      'GSIS-302': 'Not Run',
                      'GSIS-303': 'Not Run',
                      'GSIS-304': 'Not Run',
                      'GSIS-305': 'Not Run',
                      'GSIS-306': 'Not Run',
                      'GSIS-307': 'Not Run',
                      'GSIS-308': 'Manual Testcase',
                      'GSIS-309': 'Manual Testcase'}

    testAssoc = {'iscsi_01': ['GSIS-101'],
                 'iscsi_02': ['GSIS-201'],
                 'iscsi_03': ['GSIS-202'],
                 'iscsi_04': ['GSIS-203','GSIS-204'],
                 'iscsi_05': ['GSIS-101'],
                 'iscsi_06': ['GSIS-301'],
                 'iscsi_07': ['GSIS-302'],
                 'iscsi_08': ['GSIS-303'],
                 'iscsi_09': ['GSIS-304'],
                 'iscsi_10': ['GSIS-305'],
                 'iscsi_11': ['GSIS-306', 'GSIS-307']}

    map1 = "\nHCL> At this time, please map a 5G LUN to " + master +",\n     and then map a 10G LUN to " + second + ".\n    After the LUNs have been mapped, press Enter to resume: "

    testPrompt = {'iscsi_01': '\nHCL> At this time, the iSCSI tests with CHAP enabled will be executed.\n     Please ensure that your environment is configured correctly for\n     CHAP Authentication, then when you are ready to begin, press\n     Enter to resume: ',
                  'iscsi_02': '\nHCL> At this time, please map a 5G LUN and a 10G LUN to both servers.\n     After the LUNs have been mapped, press Enter to resume: ',
                  'iscsi_03': '\nHCL> At this time, please resize the LUNs from the previous test.\n     Increase the LUN sizes to 7G and 12G, respectively.\n     After the LUNs have been resized, press Enter to resume: ',
                  'iscsi_04': '\nHCL> At this time, please unmap the two LUNs from the previous step.\n     After the LUNs have been unmapped, press Enter to resume: ',
                  'iscsi_05': '\nHCL> At this time, the iSCSI generic plugin tests with CHAP disabled\n     will be executed.  Please ensure that your environment is configured\n     correctly, then when you are ready to begin, press Enter to resume: ',
                  'iscsi_06': map1,
                  'iscsi_07': '\nHCL> At this time, please resize the LUNs from the previous test.\n     Increase the LUN sizes to 7G and 12G, respectively.\n     Once the LUNs have been resized, press Enter to resume: ',
                  'iscsi_08': '\nHCL> At this time, please unmap the 7G and 12G LUNs from the previous\n     test.  After the LUNs have been unmapped, press Enter to resume: ',
                  'iscsi_09': '\nHCL> At this time, please map four new LUNs to both servers.\n     The LUNs must be the following sizes: 2G, 5G, 10G, and 30G.\n     After the LUNs have been mapped, press Enter to resume: ',
                  'iscsi_10': '\nHCL> At this time, please unmap the 2GB LUN from both servers, grow\n     the 5G LUN to 15G, and grow the 10G LUN to 20G.  The 30G LUN\n     remains the same size.  These are the required LUN sizes for\n     the remainder of the tests.  After the LUNs have been unmapped\n     and resized accordingly, press Enter to resume: ',
                  'iscsi_11': ''}
                  


    for key in sorted(testNames): 

        myList = testAssoc[key]

        if key == 'iscsi_01' and  chap == "UNSUPPORTED":
            continue
        if key == 'iscsi_02' and chap == "UNSUPPORTED":
            for testcase in myList:
                testCaseStatus[testcase] = "UNSUPPORTED"
            continue
        elif key == 'iscsi_03' and chap == "UNSUPPORTED":
            for testcase in myList:
                testCaseStatus[testcase] = "UNSUPPORTED"
            continue
        elif key == 'iscsi_04' and chap == "UNSUPPORTED":
            for testcase in myList:
                testCaseStatus[testcase] = "UNSUPPORTED"
            continue
        elif key == 'iscsi_05':
            chap = "UNSUPPORTED"

        if not testPrompt[key] == '':
            reply = raw_input(testPrompt[key])
        
        status,timelapse = kickOff(config, testNames[key], logdir, ovmPassword, ovmAgent, chap)
        totallapse = totallapse + timelapse

        if status:
            failCount = failCount + 1
            for testcase in myList:
                testCaseStatus[testcase] = "Failed"
            print "Test failures cause the environment to be in an unknown state, and therefore"
            print "the certification tests are unable to proceed at this time.  Please run the"
            print "cleanup scripts by specifying the -k option, and begin the certification run"
            print "again after all failures have been addressed.\n"
            break

        else:
            passCount = passCount + 1
            for testcase in myList:
                testCaseStatus[testcase] = "Passed"

    
    print "--------------------------------------------------------------------------"
    if failCount:
        runstatus = True
    else:
        runstatus = False
    print "Individual Test Case Results:"
    for key in sorted(testCaseStatus):
        print key + " ................................  "+testCaseStatus[key] 

    print "--------------------------------------------------------------------------"


    return runstatus,totallapse


    
def runVendorTests(config, logdir, ovmPassword, ovmAgent, protocol, storagepass):

    failCount = 0
    passCount = 0
    totallapse = 0

    testNamesFC = {'fc_01': 'Test_Suite_2-FibreChannel_AGandVM',
                   'fc_02': 'Test_Suite_2-FibreChannel_Cleanup'}
    testNames = {'iscsi_01': 'Test_Suite_2-iSCSI_AGandVM',
                 'iscsi_02': 'Test_Suite_2-iSCSI_Cleanup'}

    testPrompt = {'fc_01': '',
                  'fc_02': '\nHCL> At this time, the test environment has been set up for you to\n     execute the Multipath Failover and Failback tests.  Once you\n     have completed those tests, press Enter to resume: ',
                  'iscsi_01': '',
                  'iscsi_02': ''}


    if protocol == 'FC':
        
        for key in sorted(testNamesFC):
            if not testPrompt[key] == '':
                reply = raw_input(testPrompt[key])

            status,timelapse = kickOff(config, testNamesFC[key], logdir, ovmPassword, ovmAgent, storagepass)
            totallapse = totallapse + timelapse
                
            if status:
                failCount = failCount + 1
                print "Test failures cause the environment to be in an unknown state, and therefore"
                print "the certification tests are unable to proceed at this time.  Please run the"
                print "cleanup scripts by specifying the -k option, and begin the certification run"
                print "again after all failures have been addressed.\n"
                break
            else:
                passCount = passCount + 1
        


    else:
        for key in sorted(testNames):
            if not testPrompt[key] == '':
                reply = raw_input(testPrompt[key])

            status,timelapse = kickOff(config, testNames[key], logdir, ovmPassword, ovmAgent, storagepass)
            totallapse = totallapse + timelapse

            if status:
                failCount = failCount + 1
                print "Test failures cause the environment to be in an unknown state, and therefore"
                print "the certification tests are unable to proceed at this time.  Please run the"
                print "cleanup scripts by specifying the -k option, and begin the certification run"
                print "again after all failures have been addressed.\n"
                break
            else:
                passCount = passCount + 1
        
                        
    if failCount:
        runstatus = True
    else:
        runstatus = False

    return runstatus,totallapse
