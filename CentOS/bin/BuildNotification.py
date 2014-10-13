#!/usr/bin/env python
from __future__ import print_function

import smtplib
import mimetypes
import re
import os
import datetime
import ConfigParser
import glob
import socket

from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText


class BuildNotificationConfig( object ):

   def __init__(self, buildDate = '', iniFile = 'BuildNotification.ini'):
       self._buildDate = buildDate 
       self.config = ConfigParser.ConfigParser()

       if not self.buildDate:
          today = datetime.date.today()
          self._buildDate = today.strftime("%Y-%m-%d")
          #print(self._buildDate) 

       self.config.read( iniFile )

   def get( self, section, key ):
      try:
         return self.config.get( section, key )
      except: 
         return None

   @property
   def buildDate( self ):
       return self._buildDate

   @property
   def reportDirectory( self ):
       return  "{buildDate}/{buildSystem}/{buildDirectory}".format(
                 buildDate=self.buildDate,
                 buildSystem=self.get( 'Build', 'BuildSystem' ),
                 buildDirectory=self.get( 'Build', 'BuildDirectory' ))

   @property
   def reportDirectoryURL( self ):
       return  "{urlBase}/{reportDirectory}".format(
                 urlBase=self.get( 'Build', 'urlBase' ),
                 reportDirectory=self.reportDirectory )

   @property
   def reportDirectoryFileSystem( self ):
       return  "{shareBase}/{reportDirectory}".format(
                 shareBase=self.get( 'Build', 'shareBase' ),
                 reportDirectory=self.reportDirectory )


class Task( object ):

    def __init__( self, name, config ):
        self._name = name
        self.config = config
        self._status = 'FAILED'
        self._result = ''
        self._gitBranch = 'master'
        self._logFileName = self.getLogFileName()

   
    def getLogFileName( self ):
        return "Unimplementated"

    @property
    def name( self ):
        return self._name

    @property
    def status( self ):
        return self._status

    @property
    def result( self ):
        return self._result

    @property
    def gitBranch( self ):
        return self._gitBranch


    @property
    def logFileName( self ):
        if not self._logFileName:
            self._logFileName = self.getLogFileName()

        return self._logFileName
   


class BuildTask( Task ):    

    
    def getLogFileName( self ):
        return self.config.get( 'Build', 'BuildLog' )
     
    @property
    def logFileURL( self ):
        return "{reportDirectoryURL}/{logFile}".format(
                 reportDirectoryURL=self.config.reportDirectoryURL,
                 logFile=self.logFileName)

    @property
    def gitLogFileURL( self ):
        return "{reportDirectoryURL}/git_2days_log".format(
                 reportDirectoryURL=self.config.reportDirectoryURL)
                 

    @property
    def logFileFileSystem( self ):
        return "{reportDirectoryFileSystem}/{logFile}".format(
                 reportDirectoryFileSystem=self.config.reportDirectoryFileSystem,
                 logFile=self.config.get( 'Build', 'BuildLog' ))

    @property
    def gitLogFileSystem( self ):
        return "{reportDirectoryFileSystem}/git_2days_log".format(
                 reportDirectoryFileSystem=self.config.reportDirectoryFileSystem)


    def processResult( self ):
        self._status = self._result = 'FAILED'
        print("Build log: " + self.logFileFileSystem)
        if not os.path.exists( self.logFileFileSystem ): 
           self._status = self._result = 'UNAVAILABLE'
           return

        i = 5
        p = re.compile('\s*Build succeed\s*$')
        for line in reversed( open( self.logFileFileSystem ).readlines( )):
           m = p.match( line )
           if m:
              self._status = self._result = 'PASSED'
              break
          
           i -= 1
           #print( line, end='' )
           if i == 0: break 


        p = re.compile('\s*git branch:\s*(.*)$')
        for line in open( self.gitLogFileSystem ).readlines( ):
           m = p.match( line )
           if m:
              self._gitBranch = m.group(1) 
              break
       

class TestTask( Task ):    

    @property
    def logFileDirectory( self ):
        return "{reportDirectoryFileSystem}/test".format(
                 reportDirectoryFileSystem=self.config.reportDirectoryFileSystem )

    def getLogFileName( self ):    
        nameInLower = self.name.lower()
        logFile = ""
        if os.path.exists( self.logFileDirectory + "/" + nameInLower + ".log" ): 
           logFile = nameInLower + ".log"
        else:
           curDir = os.getcwd()
           os.chdir( self.logFileDirectory )
           files = glob.glob( nameInLower + \
                ".[0-9][0-9]-[0-9][0-9]-[0-9][0-9]-[0-9][0-9]-[0-9][0-9]-[0-9][0-9].log" )
           if files: 
              sortedFiles = sorted( files, key=str.lower, reverse=True )
              logFile = sortedFiles[0]

           os.chdir( curDir )

        return logFile


    @property
    def logFileURL( self ):
        return "{reportDirectoryURL}/test/{logFile}".format(
                 reportDirectoryURL=self.config.reportDirectoryURL,
                 logFile=self.getLogFileName())
                 

    @property
    def logFileFileSystem( self ):
        return "{reportDirectoryFileSystem}/{logFile}".format(
                 reportDirectoryFileSystem=self.logFileDirectory,
                 logFile=self.getLogFileName( ))

    @property
    def summaryFile( self ):
        nameInLower = self._name.lower()
        return "{reportDirectoryFileSystem}/test/{name}.summary".format(
                 reportDirectoryFileSystem=self.config.reportDirectoryFileSystem,
                 name=nameInLower )

    def processResult( self ):
       if not os.path.exists( self.summaryFile ): 
          self._status = self._result = 'UNKNOWN'
          return
       
       p = re.compile('\s*TestResult:(.*)\s*$')
       p2 = re.compile('.*failed:([0-9]+)\s*$')
       for line in reversed( open( self.summaryFile ).readlines( )):
          m = p.match( line )
          if m:
             self._result = m.group(1)
             self._status = 'PASSED'
             m2 = p2.match( self._result )
             if m2 and  (m2.group(1) !=  '0'):
                 self._status = 'FAILED'

             break 


       
class BuildNotification( object ):

   def __init__( self, config ):
       self.config = config 
       self.hasBuild = True
       self.summary = ''
       self.status = ''
       self.results = []
       self.tasks = [ 'Install', 'Setup', 'Hthor', 'Thor', 'Roxie', 'Uninstall' ]
       self.msg = MIMEMultipart('alternative')
       self.msgHTML = ''
       self.msgText = ''
           

   def processResults( self ):
       buildTask = BuildTask( 'Build', self.config ) 
       self.results.append( buildTask )
       buildTask.processResult()
       self.status = 'PASSED'
       if buildTask.status == "PASSED":
          for taskName in self.tasks:
              task = TestTask( taskName, self.config ) 
              task.processResult()
              self.results.append( task )
              if task.status != "PASSED": self.status = 'PARTIAL'
       else: 
          self.summary = 'Build Failed'
          self.status = 'FAILED'

          
          
       #for task in self.results:
       #   print( "\nName: " + task.name )
       #   print( "Status: " + task.status )
       #   print( "Result: " + task.result )
       #   print( "Log: " + task.logFileURL )


   def headRender( self ):

       #self.msg['Subject'] = "HPCC Nightly Build " + self.config.buildDate + " Result: " + self.status 
       self.msg['From'] = self.config.get( 'Email', 'Sender' )
       self.msg['To'] = self.config.get( 'Email', 'Receivers' ) 

       print("Build Result " + self.status)
       print("From " + self.msg['From'])
       print("To " + self.msg['To'])
       self.msgHTML = """\
<html>
  <head></head>
  <body>
    <p>
      <H3>HPCC Community Platform Nightly Build Report:</H3><br/>
      Build date: """ + self.config.buildDate + "<br/>Build system: " + self.config.get('Build', 'BuildSystem')  + \
       "  IP: " + "10.176.32.5" + "<br/>Build on git branch " + self.results[0].gitBranch
#       "  IP: " + socket.gethostbyname(socket.gethostname()) + "<br/>Build on git branch " + self.results[0].gitBranch

#      "  IP: " + "127.0.0.1" + "<br/>Build on git branch " + self.results[0].gitBranch
#
# !!!!!!!!!!!!!!!!!!!!!
# Name server doesn't respond and socket.gethostbyname() throws exception
#
#      "  IP: " + socket.gethostbyname(socket.gethostname()) + "<br/>Build on git branch " + self.results[0].gitBranch
# Already fixed on 07/14
#

      

       self.msgHTML += """\
    </p>"""


   def endRender( self ):
       self.msgHTML += """\
  </body>
</html>
"""

   def taskRender( self ):
       self.msgHTML += """\
   <table width="600" cellspacing="0" cellpadding="0" border="1" bordercolor="#828282">
     <TR style="background-color:#CEE3F6"><TH>Task</TH><TH>Status</TH><TH>Log</TH>
"""
    
       subjectSuffix=''

       for task in self.results:
           result = task.result
           p = re.compile('(.*)otal:([0-9]+) passed:([0-9]+) failed:([0-9]+)\s*$')

           if( task.result == "PASSED" ):
               result = "<span style=\"color:green\">" + task.result + "</span>" 
           elif( task.result == "FAILED" ):
               result = "<span style=\"color:red\">" + task.result + "</span>" 
           elif(( task.result == "UNKNOWN" ) or ( task.result == "UNAVAILABLE" )):
               result = "<span style=\"color:orange\">" + task.result + "</span>" 
           else: 
               unprocessed_result = result
               result = ""
               for str in unprocessed_result.split(','):
                   str = str.strip()
                   m = p.match( str )
                   if m:
                       passedNum = m.group(3)
                       failedNum = m.group(4)
                       if( int(passedNum) > 0 ):  
                           passedNum = "<span style=\"color:green\">" + passedNum + "</span>"
                 
                       if ( int(failedNum) > 0 ):
                           subjectSuffix += ' ' + failedNum+' ' + task.name
                           failedNum = "<span style=\"color:red\">" + failedNum + "</span>"

                       elif ( int(m.group(2)) > 0 ) and ( m.group(1) == m.group(2) ):  
                           failedNum = "<span style=\"color:green\">" + failedNum + "</span>"
                       if result: 
                          result = result + "<br/>"
                       result += m.group(1) + "otal:" + m.group(2) + " passed:" + passedNum + " failed:" + failedNum


           self.msgHTML += """
        <TR align="center"><TD>"""
           self.msgHTML += task.name + "</TD><TD>" + result + "</TD><TD>"
           if( task.name == "Build" ):
              self.msgHTML += "<a href=\"" + task.gitLogFileURL + "\" target=\"_blank\">git_log, </a>"
              self.msgHTML += "<a href=\"" + task.logFileURL + "\" target=\"_blank\">" + task.logFileName + "</a>"
           elif( task.name == "Setup" ):
              subTasks = [ 'setup_hthor', 'setup_thor', 'setup_roxie' ]
              for st in subTasks:
                subTask = TestTask( st, self.config )
                self.msgHTML += "<a href=\"" + subTask.logFileURL + "\" target=\"_blank\">" + subTask.logFileName + "</a><br/>"
                 
           else:
              self.msgHTML += "<a href=\"" + task.logFileURL + "\" target=\"_blank\">" + task.logFileName + "</a>"
           self.msgHTML += "</TD></TR>"

       if self.status != "PASSED":
           subjectSuffix += " failure"
       else:
           subjectSuffix += self.status

       self.msg['Subject'] = "HPCC Nightly Build " + self.config.buildDate + " Result: " + subjectSuffix

       self.msgHTML += """\
   </table>
   <ul>
     <li><a href="http://10.176.152.123/wiki/index.php/HPCC_Nightly_Builds" tarkget="_blank">Nightly Builds Web Page</a></li> 
     <li><a href="http://10.176.152.123/data2/nightly_builds/HPCC/5.0/" tarkget="_blank">Nightly Builds Archive</a></li> 
     <li><a href="http://10.176.32.10/builds/" tarkget="_blank">HPCC Builds Archive</a></li> 
   </ul>
"""


   def send( self ): 
       #self.msg.attach( MIMEText( self.msgText, 'plain' )) 
       self.msg.attach( MIMEText( self.msgHTML, 'html' ))  
        
       toList = self.msg['To'].split( ',' )
       
       try:
           smtpObj = smtplib.SMTP( 'mailout.br.seisint.com', 25 )
           smtpObj.sendmail( self.msg['From'], toList, self.msg.as_string() )
           #print( self.msg.as_string() )
       except smtplib.SMTPException:
           print( "Error: unable to send email" )
       

if __name__ == "__main__":
    config = BuildNotificationConfig()
    bn = BuildNotification(config)
    bn.processResults()
    bn.headRender()
    bn.taskRender()
    bn.endRender()
    bn.send()

