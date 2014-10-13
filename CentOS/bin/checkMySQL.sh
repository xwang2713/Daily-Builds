#!/bin/bash

#
#------------------------------
#
# Import settings
#
# Git branch

. ./settings.sh

# WriteLog() function

. ./timestampLogger.sh

#
#------------------------------
#
# Constants
#

BUILD_HOME=~/build/CE/platform/build
LONG_DATE=$(date "+%Y-%m-%d_%H-%M-%S")
MYSQL_CHECK_LOG_FILE=${BUILD_HOME}/checkMySQL-${LONG_DATE}.log

tryCount=2

#
#------------------------------
#
# Check the state of MySQl Server
#

WriteLog "Start MySQL Server check" "${MYSQL_CHECK_LOG_FILE}"

while [[ $tryCount -ne 0 ]]
do
    echo "Try count:"$tryCount
    mysqlstate=$( service mysqld status | grep 'running')
    if [[ -z $mysqlstate  ]]
    then
        echo "Stoped! Start it!"
	WriteLog "Stoped! Start it!" "${MYSQL_CHECK_LOG_FILE}"
        service mysqld start
        sleep 5
        tryCount=$(( $tryCount-1 ))
        continue
    else
        echo "Ok!"
	WriteLog "It is OK!" "${MYSQL_CHECK_LOG_FILE}"
        break
    fi
done
if [[ $tryCount -eq 0 ]]
then
    echo "Give up!"
    WriteLog "MySQL won't start! Give up and send Email to Agyi!" "${MYSQL_CHECK_LOG_FILE}"
    # send email to Agyi
    echo "MySQL won't start!" | mailx -s "Problem with MySQL" -u root  "attila.vamos@gmail.com"

fi
echo 'End.'

WriteLog "End." "${MYSQL_CHECK_LOG_FILE}"