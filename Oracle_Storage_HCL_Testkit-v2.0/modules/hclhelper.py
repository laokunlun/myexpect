
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
import ConfigParser
from collections import deque

globalvars = {"CONFIGFILE": "UNDEFINED",
              "DATETIME": "UNDEFINED",
              "EXIT_SUCCESS": 0,
              "EXIT_FAILURE": 1,
              "LOGDIR": "UNDEFINED",
              "PWD": "UNDEFINED",
              "VERBOSE": False}

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

class HCLERROR(Exception):
    def __init__(self, value):
        self.value = value
    def __str__(self):
        return repr(self.value)



### Explain what TDFs are
class TDF(object):

    def __init__(self):
        self.data = {}
        self.o_args = {}
        self.p_args = deque([])
        self.keys = []

    def copy(self):
        return copy.deepcopy(self)

    def get_testdata(self, name):
        if name in self.data:
            return self.data[name]
        else:
            return False
    
    def set_testdata(self, name, value):
        if type(value) is str:
            value = value.strip()
        self.data[name] = value
        self.keys.append(name)

    def key_exists(self, name):
        if name in self.keys:
            return True
        else:
            return False

    def append_testdata(self, name, value):
        self.data[name].append(value)

    def enqueue_p_arg(self, name):
        self.p_args.append(name)

    def dequeue_p_arg(self):
        if self.p_args:
            return self.p_args.popleft()
        else:
            return None

    def get_positional_string(self):
        if self.p_args:        
            myTemp = deque(self.p_args)
            myPosArgs = str(self.data[self.p_args.popleft()])
            while self.p_args:
                myPosArgs = myPosArgs +" "+ str(self.data[self.p_args.popleft()])
            self.p_args = myTemp
            return myPosArgs
        else:
            return ""

    def set_optional_arg(self, name, value):
        self.o_args[name] = value

    def get_optional_arg(self, name):
        if name in self.o_args:
            return self.o_args[name]
        else:
            return False

    def get_optional_string(self):
        myOptArgs = ""
        for key in self.o_args:
            myOptArgs = myOptArgs+" "+key+" "+self.o_args[key]
        return myOptArgs
        

    def __eq__(self, other):
        if other.data == self.data and other.p_args == self.p_args:
            return True
        else:
            return False

    def __ne__(self, other):
        if other.data == self.data and other.p_args == self.p_args:
            return False
        else:
            return True




### Explain what TSDs are
class TSD(object):

    def __init__(self):
        self.data = {}
        self.o_args = {}
        self.p_args = deque([])
        self.keys = []

    def copy(self):
        return copy.deepcopy(self)






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
    

def getTestNames():
    myTDF_Dir = globalvars["PWD"] + "/TDF/"
    print Colors.WARNING+"\n\nThe available test names are:"+Colors.ENDC
    for files in os.listdir(myTDF_Dir):
        if files.endswith(".ini"):
            print files[:-4]
    print "\n"
    return


def verifyTestName(testname):

    verify = True
    myTDF_Dir = globalvars["PWD"] + "/TDF/"
    
    if testname.endswith('.ini'):
        myTDF = myTDF_Dir+testname
    else:
        myTDF = myTDF_Dir+testname+".ini"
        
    if not os.path.exists(myTDF):
        verify = False
        print "\n"+Colors.WARNING+"The test file "+testname+" does not exist!\n"+Colors.ENDC
        print "The available test names are:"
        for files in os.listdir(myTDF_Dir):
            if files.endswith(".ini"):
                print files[:-4]
        print "\n"

    elif not os.path.isfile(myTDF):
        verify = False
        print "\n"+Colors.WARNING+"The test file "+testname+" is not a file!\n"+Colors.ENDC

    return verify



def parseTDF(testname):
 
    myTDF_Dir = globalvars["PWD"] + "/TDF/"
    
    if testname.endswith('.ini'):
        myTDF = myTDF_Dir+testname
    else:
        myTDF = myTDF_Dir+testname+".ini"

    config = ConfigParser.ConfigParser()
    config.read(myTDF)

    myTest = TDF()
    tdf_sections = config.sections()
    tdf_sections.sort()
    
    for section in tdf_sections:
        if section == "Test":
            myTest.set_testdata("testname", config.get('Test', "name"))
            myTest.set_testdata("exec_str", config.get('Test', "exec").replace("%PWD%", globalvars["PWD"]))
        elif section == "Passwords":
            passwd_prompts = config.options('Passwords')
            for passwd in passwd_prompts:
                myTest.set_testdata(passwd, getPassWD(config.get('Passwords', passwd)))
        elif section == "Positional Arguments":
            argcs = config.options('Positional Arguments')
            argcs.sort()
            for arg in argcs:
                arg_name = config.get('Positional Arguments', arg)
                
                ## Positional arguments can be three types:
                ## - passwords (already prompted for in the Passwords section)
                ## - framework environmental variables - pre-defined by the framework
                ## - user-defined
                ## Passwords and framework environmental variables will 
                ## have already been defined, and we can pull them from
                ## the objects data list.

                ## This is a framework defined parameter
                if (re.match(r'%.+?%', arg_name)):
                    arg_name = arg_name.strip('%')
                    if not arg_name in globalvars:
                        raise HCLERROR('Fatal Failure: Undefined Framework Variable: '+arg_name+' in '+myTDF+' TDF File.')
                    elif globalvars[arg_name] == "UNDEFINED":
                        raise HCLERROR("Fatal Failure: A value for "+arg_name+" has not been defined!")
                    else:
                        print "DEBUG:  Adding "+arg_name+" = "+str(globalvars[arg_name])+" to the object"
                        myTest.set_testdata(arg_name, globalvars[arg_name])
                        myTest.enqueue_p_arg(arg_name)
                ## This is a password, which we should have already prompted the user to enter
                elif (re.search(r'password', arg_name)):
                    if not myTest.key_exists(arg_name):
                        raise HCLERROR("Fatal Failure: "+arg_name+" is a password, but it was not defined in the Passwords section of the "+myTDF+" TDF File.")
                    else:
                        myTest.enqueue_p_arg(arg_name)
                ## This is a user-defined value, and the string will be the value
                ## that needs to be passed in.
                else:
                    myTest.set_testdata(arg_name, arg_name)
                    myTest.enqueue_p_arg(arg_name)
                    
        elif section == "Optional Arguments":
            argcs = config.options('Optional Arguments')
            for arg in argcs:
                print "DEBUG:  Setting optional value: "+arg
                arg_val = config.get('Optional Arguments', arg)
                myTest.set_optional_arg(arg, arg_val)

        elif section == "Exit Status":
            myTest.set_testdata('exit_success',config.get("Exit Status","success"))
            myTest.set_testdata('exit_failure',config.get("Exit Status","failure"))

        else:
            ### FIXME!!! Need to do something will all sections!!
            print "DEBUG:  OH HAI, from the "+section+" section!"
        

    return myTest


def kickOff(testTDF):

    myTestName = testTDF.get_testdata("testname")
    myExitStatus = False

    print "\n\n"
    print Colors.HEADER+"--------------------------------------------------------------------------"
    print "Beginning output for "+myTestName
    print "--------------------------------------------------------------------------\n\n"+Colors.ENDC
    
    startTime = time.time()
    expectScriptExitCode = None

    myProc = testTDF.get_testdata("exec_str")+" "+testTDF.get_positional_string() +" "+ testTDF.get_optional_string()

    try:
        expectScriptExitCode = subprocess.call(myProc, shell=True)
    finally:
        endTime = time.time()
        timelapse = int(endTime - startTime)

    if (str(expectScriptExitCode) == testTDF.get_testdata('exit_success')):
        print Colors.OK+myTestName+": "+Colors.PASS+"PASSED\n"+Colors.ENDC
        myExitStatus = True
    else:
        print Colors.OK+myTestName+": "+Colors.FAIL+"FAILED\n"+Colors.ENDC
        print "\nUnexpected errors occurred during the execution of the certification tests"
        print "leaving the environment in an unknown state which will prevent all further"
        print "tests from executing cleanly.\nExiting.\n"
        myExitStatus = False
                
    print "Please view the logs in " + globalvars["LOGDIR"] + " for further details."
    print "\n\nExecution of " + myTestName + " completed after " + str(timelapse / 60) + "." + str(timelapse % 60) + " minutes."
    print "\n\n--------------------------------------------------------------------------"
    print "--------------------------------------------------------------------------\n\n"

    return timelapse,myExitStatus

## Make sure the config file exists and is really a file.
## Once we establish that, more checking can be done.
def verifyConfig(config, logdir):

    verify = True
    if config == "UNDEFINED":
        raise HCLERROR("Fatal Failure: Expected a value for CONFIGFILE, but it was undefined!")
    
    if not os.path.exists(config):
        verify = False
        print "\n"+Colors.WARNING+"The configuration file "+config+" does not exist!\n"+Colors.ENDC
    elif not os.path.isfile(config):
        verify = False
        print "\n"+Colors.WARNING+"The configuration file "+config+" is not a file!\n"+Colors.ENDC

    if not verify:
        print "Please rerun the script, and provide the full path"
        print "to an existing configuration file. To generate a new"
        print "config file, run the script with the --new-config"
        print "option set, specifying the desired certification type."
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



## Package up the log files into a tarfile for easy transport
def packageLogs(logroot, logdir, timestamp):

    myTGZ = logroot + "ovm-storage-hcl_" + str(timestamp) + ".tgz"
    try:
        r = subprocess.Popen(["tar", "czf", myTGZ, logdir], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    except:
        print "Unable to package " + logdir + " into " + myTGZ + ".\nExiting.\n" 
        sys.exit(2)



def getFileName(pathname):
    
    parts = pathname.split('/')
    length = len(parts)
    
    if parts[length - 1] == '':
        return parts[length - 2]
    else:
        return parts[length - 1]


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

    if globalvars["VERBOSE"]:
        print msg




