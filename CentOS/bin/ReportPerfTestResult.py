#!/usr/bin/env python

import os
import smtplib
import ConfigParser
import datetime
import glob

from email.mime.multipart import MIMEMultipart
from email.MIMEBase import MIMEBase
from email.MIMEText import MIMEText
from email.Utils import COMMASPACE, formatdate
from email import Encoders

msgText = MIMEMultipart('alternative') 

class BuildNotificationConfig( object ):

   def __init__(self, buildDate = '', iniFile = 'ReportPerfTestResult.ini'):
       self._buildDate = buildDate 
       self.config = ConfigParser.ConfigParser()
       self.config.read( iniFile )

   def get( self, section, key ):
      try:
         return self.config.get( section, key )
      except: 
         return None 
         
def createMsg(config):
    logDir = config.get( 'Environment', 'LogDir' ) 
    curDir = os.getcwd()
    os.chdir( logDir )
    tests = config.get( 'Performance', 'TestList' ) .split(',')
    msgText['From'] = config.get( 'Email', 'Sender')
    msgText['To']     = config.get( 'Email', 'Receivers')
    _buildDate = datetime.date.today().strftime("%Y-%m-%d")
    
    #Begin HTML
    msgHTML = """\
<html>
    <head></head>
    <body>
        <p>
            <H3>HPCC Community Platform Nightly Performance Test Report:</H3><br/> 
     """
    # some build info here
    
    msgHTML += """\
        <table width="600" cellspacing="0" cellpadding="0" border="1" bordercolor="#828282">
            <TR style="background-color:#CEE3F6"><TH>Target</TH><TH>Status</TH><TH>Log</TH>
"""

    subjectSuffix='Result:'
    for test in tests:
        queries = ''
        passed = ''
        failed = ''
        file = test+"-performance-test.log" 
        files = glob.glob( test + \
                ".[0-9][0-9]-[0-9][0-9]-[0-9][0-9]-[0-9][0-9]-[0-9][0-9]-[0-9][0-9].log" )
        if files: 
            sortedFiles = sorted( files, key=str.lower, reverse=True )
            file = sortedFiles[0] 
        print file
        temp = open(file).readlines( )
        for line in temp:
            if 'Queries:' in line:
                fields = line.split()
                queries = fields[1]
                
            elif 'Passing:' in line:
                fields = line.split()
                passed = fields[1]
            
            elif 'Failure:' in line:
                fields = line.split()
                failed = fields[1]
                if failed != '0':
                  subjectSuffix += ' ' + failed +' ' + test

        result = 'total:'+queries+' passed:'+passed+' failed:'+failed
        
        part = MIMEBase('application', 'octet-stream')
        part.set_payload( ''.join(temp))
        Encoders.encode_base64(part)
        part.add_header('Content-Disposition', 'attachment; filename="%s"' % file)
        msgText.attach(part)
        
        # Test results HTML
        msgHTML += """
            <TR align="center"><TD>"""
        msgHTML += test + "</TD><TD>" + result + "</TD><TD>"
        logFileUrl = config.get( 'Environment', 'urlBase' ) +'/'+_buildDate+'/'
        logFileUrl += config.get( 'Environment', 'BuildSystem' ) +'/'
        logFileUrl += config.get( 'Environment', 'BuildDirectory' ) +'/test/'+file
        msgHTML += "<a href=\"" + logFileUrl + "\" target=\"_blank\">" + file + "</a>" 
        msgHTML += "</TD></TR>\n" 

    if subjectSuffix == 'Result:':
        subjectSuffix += " PASSED"
    else:
        subjectSuffix += " failure"

    msgText['Subject'] = "Performance Test Result on " + _buildDate + " " + subjectSuffix 

    # End HTML
    msgHTML += """\
        </table>
        <ul>
            <li><a href="http://10.176.152.123/wiki/index.php/HPCC_Nightly_Builds" tarkget="_blank">Nightly Builds Web Page</a></li> 
            <li><a href="http://10.176.152.123/data2/nightly_builds/HPCC/5.0/" tarkget="_blank">Nightly Builds Archive</a></li> 
            <li><a href="http://10.176.32.10/builds/" tarkget="_blank">HPCC Builds Archive</a></li> 
        </ul>  
    </body>
</html>
"""

    msgText.attach( MIMEText( msgHTML, 'html' ))

    os.chdir( curDir ) 

    pass

def send(config): 
       fromaddr= config.get( 'Email', 'Sender' )
       toList = config.get( 'Email', 'Receivers' ).split(',')
       server = config.get( 'Email', 'SMTPServer' )
       try:
           smtpObj = smtplib.SMTP( server, 25 )
           smtpObj.sendmail( fromaddr, toList, msgText.as_string() )
       except smtplib.SMTPException:
           print( "Error: unable to send email" )
       
       smtpObj.quit()

if __name__ == "__main__":
        config = BuildNotificationConfig() 
        createMsg(config)
        send(config)

