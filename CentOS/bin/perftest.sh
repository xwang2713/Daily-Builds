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

PERF_TEST_ROOT=~/perftest
PERF_TEST_HOME=~/perftest/ecl-bundles/PerformanceTesting
TEST_ROOT=~/build/CE/platform
TEST_ENGINE_HOME=${TEST_ROOT}/HPCC-Platform/testing/regress
BUILD_HOME=~/build/CE/platform/build
BUILD_DIR=/root/build
BIN_HOME=~/build/bin
LONG_DATE=$(date "+%Y-%m-%d_%H-%M-%S")
PERF_TEST_LOG=${BUILD_HOME}/perf_test-${LONG_DATE}.log

#
#----------------------------------------------------
#
# Start Performance Test process
#

WriteLog "Performance Test started" "${PERF_TEST_LOG}"

#
#---------------------------
#
# Clean system
#

WriteLog "Clean system" "${PERF_TEST_LOG}"

echo ""
echo "Clean system"

[ ! -e $PERF_TEST_ROOT ] && mkdir -p $PERF_TEST_ROOT

rm -rf ${PERF_TEST_ROOT}/*
cd  ${PERF_TEST_ROOT}

 
#
#---------------------------
#
# Uninstall HPCC to free as much disk space as can
#

WriteLog "Uninstall HPCC to free as much disk space as can" "${PERF_TEST_LOG}"


echo ""
echo "Uninstall HPCC-Platform" 
#echo "Uninstall HPCC-Platform" > ${PERF_TEST_LOG} 2>&1

/opt/HPCCSystems/sbin/complete-uninstall.sh


#
#--------------------------------------------------
#
# Build it
#
WriteLog "Build HPCC Platform..." "${PERF_TEST_LOG}"

cd ${BUILD_HOME}

date=$( date +%Y-%m-%d_%H-%M-%S)
echo "Start at "$date
#echo "Start at "$date > build.log 2>&1


res=$( ${BUILD_DIR}/bin/build_pf.sh HPCC-Platform 2>&1 )
WriteLog "build config:${res}" "${PERF_TEST_LOG}"


res=$( make -j 8 package 2>&1 )
WriteLog "build result:${res}" "${PERF_TEST_LOG}"

if [ $? -ne 0 ] 
then
   WriteLog "Build failed: build has errors " "${PERF_TEST_LOG}"
   buildResult=FAILED
else
   ls -l hpcc*.rpm >/dev/null 2>&1
   if [ $? -ne 0 ] 
   then
      WriteLog "Build failed: no rpm package found " "${PERF_TEST_LOG}"
      buildResult=FAILED
   else
      WriteLog "Build succeed" "${PERF_TEST_LOG}"
      buildResult=SUCCEED
   fi
fi

date=$( date +%Y-%m-%d_%H-%M-%S)
echo "Build end at "$date

#TARGET_DIR=${STAGING_DIR}/${DATE}/${BUILD_SYSTEM}/${BUILD_TYPE}

#if [ ! -e "${TARGET_DIR}" ] 
#then
#   mkdir -p  $TARGET_DIR
#   chmod 777 ${STAGING_DIR}/${DATE}
#fi

#cp git_2days_log  $TARGET_DIR/
#cp build.log  $TARGET_DIR/
#cp hpcc*.rpm  $TARGET_DIR/
#if [ "$buildResult" = "SUCCEED" ]
#then
#   echo "BuildResult:SUCCEED" >   $TARGET_DIR/build_summary
#   WriteLog "BuildResult:SUCCEED" "${OBT_LOG_FILE}"
# 
#else
#   echo "BuildResult:FAILED" >   $TARGET_DIR/build_summary
#   WriteLog "BuildResult:FAILED" "${OBT_LOG_FILE}"
#
#fi


#
# --------------------------------------------------------------
# Install HPCC
#

WriteLog "Install HPCC Platform" "${PERF_TEST_LOG}"

echo ""
echo "Install HPCC-Platform"
#echo "Install HPCC-Platform" >> ${PERF_TEST_LOG} 2>&1

rpm -i --nodeps ${BUILD_HOME}/hpccsystems-platform_community*.rpm

if [ $? -ne 0 ]
then
   echo "Error in install!"
   WriteLog "Error in install!" "${PERF_TEST_LOG}"
   exit
fi

#
#---------------------------
#
# Patch environment.xml to use 4GB Memory
#

WriteLog "Patch environment.xml to use 4GB Memory" "${PERF_TEST_LOG}"

echo ""
echo "Patch environment.xml"
#echo "Patch environment.xml" >> ${PERF_TEST_LOG} 2>&1

cp /etc/HPCCSystems/environment.xml /etc/HPCCSystems/environment.xml.bak
sed 's/totalMemoryLimit="1073741824"/totalMemoryLimit="4294967296"/g' "/etc/HPCCSystems/environment.xml" > temp.xml && mv -f temp.xml "/etc/HPCCSystems/environment.xml"


#
#---------------------------
#
# Check HPCC Systems
#

WriteLog "Check HPCC Systems" "${PERF_TEST_LOG}"

echo ""
echo "Start HPCC Systems"
#echo "Start HPCC Systems" >> ${PERF_TEST_LOG} 2>&1

hpccRunning=$( /etc/init.d/hpcc-init status | grep -c "running")
if [[ $hpccRunning -le 10 ]]
then
    echo "Restart HPCC System..."
    WriteLog "Restart HPCC System..." "${PERF_TEST_LOG}"
    sudo /etc/init.d/hpcc-init restart
else
    echo Start HPCC system
    WriteLog "Start HPCC System" "${PERF_TEST_LOG}"
    sudo /etc/init.d/hpcc-init start
fi

# give it some time
sleep 5

#
#---------------------------
#
# Get test from github
#

WriteLog "Get Performance Test Boundle from github" "${PERF_TEST_LOG}"

cd  ${PERF_TEST_ROOT}

WriteLog "Pwd: "$(pwd) "${PERF_TEST_LOG}"

echo ""
echo "Get test from github"
#echo "Get test from github" >> ${PERF_TEST_LOG} 2>&1

git clone https://github.com/hpcc-systems/ecl-bundles.git

cd ${TEST_ENGINE_HOME}


#
#---------------------------
#
# Run performance tests on thor
#

WriteLog "Run performance tests on thor (pwd:"$(pwd)")" "${PERF_TEST_LOG}"

echo ""
echo "./ecl-test --suiteDir ${PERF_TEST_HOME} --timeout -1 -fthorConnectTimeout=36000 run -t thor -e stress"
WriteLog "./ecl-test --suiteDir ${PERF_TEST_HOME} --timeout -1 -fthorConnectTimeout=36000 run -t thor -e stress" "${PERF_TEST_LOG}"


./ecl-test --suiteDir ${PERF_TEST_HOME} --timeout -1 -fthorConnectTimeout=36000 run -t thor -e stress


#
#---------------------------
#
# Archive thor performance logs
#

WriteLog "Archive thor performance logs" "${PERF_TEST_LOG}"

/root/build/bin/archiveLogs.sh performance-thor

#
#---------------------------
#
# Uninstall HPCC to free as much disk space as can
#

WriteLog "Uninstall HPCC to free as much disk space as can" "${PERF_TEST_LOG}"

echo ""
echo "Uninstall HPCC-Platform"
#echo "Uninstall HPCC-Platform" >> ${PERF_TEST_LOG} 2>&1

/opt/HPCCSystems/sbin/complete-uninstall.sh


#
# --------------------------------------------------------------
# Install HPCC
#

WriteLog "Install HPCC Platform" "${PERF_TEST_LOG}"

echo ""
echo "Install HPCC-Platform"
#echo "Install HPCC-Platform" >> ${PERF_TEST_LOG} 2>&1

rpm -i --nodeps ${BUILD_HOME}/hpccsystems-platform_community*.rpm

if [ $? -ne 0 ]
then
   echo "Error in install!"

   exit
fi

#
#---------------------------
#
# Patch environment.xml to use 4GB Memory
#

WriteLog "Patch environment.xml to use 4GB Memory" "${PERF_TEST_LOG}"

echo ""
echo "Patch environment.xml"
#echo "Patch environment.xml" >> ${PERF_TEST_LOG} 2>&1

cp /etc/HPCCSystems/environment.xml /etc/HPCCSystems/environment.xml.bak
sed 's/totalMemoryLimit="1073741824"/totalMemoryLimit="4294967296"/g' "/etc/HPCCSystems/environment.xml" > temp.xml && mv -f temp.xml "/etc/HPCCSystems/environment.xml"


#
#---------------------------
#
# Check HPCC Systems
#

WriteLog "Check HPCC Systems" "${PERF_TEST_LOG}"

echo ""
echo "Start HPCC Systems"
#echo "Start HPCC Systems" >> ${PERF_TEST_LOG} 2>&1

hpccRunning=$( /etc/init.d/hpcc-init status | grep -c "running")
if [[ $hpccRunning -le 10 ]]
then
    echo "Restart HPCC System..."
    WriteLog "Restart HPCC System..." "${PERF_TEST_LOG}"
    sudo /etc/init.d/hpcc-init restart
else
    echo Start HPCC system
    WriteLog "Start HPCC System" "${PERF_TEST_LOG}"
    sudo /etc/init.d/hpcc-init start
fi

# give it some time
sleep 5

#
#---------------------------
#
# Run performance tests on roxie
#

WriteLog "Run performance tests on roxie" "${PERF_TEST_LOG}"

echo ""
echo "./ecl-test --suiteDir ${PERF_TEST_HOME} --timeout -1 -fthorConnectTimeout=36000 run -t roxie -e stress --pq 2"
WriteLog "./ecl-test --suiteDir ${PERF_TEST_HOME} --timeout -1 -fthorConnectTimeout=36000 run -t roxie -e stress --pq 2" "${PERF_TEST_LOG}"


./ecl-test --suiteDir ${PERF_TEST_HOME} --timeout -1 -fthorConnectTimeout=36000 run -t roxie -e stress --pq 2


#
#---------------------------
#
# Archive roxie performance logs
#

WriteLog "Archive roxie performance logs" "${PERF_TEST_LOG}"

/root/build/bin/archiveLogs.sh performance-roxie

#
#---------------------------
#
# Stop HPCC Systems
#

WriteLog "Stop HPCC Systems" "${PERF_TEST_LOG}"

echo ""
echo "Stop HPCC Systems"
#echo "Stop HPCC Systems" >> ${PERF_TEST_LOG} 2>&1

hpccRunning=$( /etc/init.d/hpcc-init status | grep -c "running")
echo $hpccRunning' running component(s)'
WriteLog "${hpccRunning} running component(s)" "${PERF_TEST_LOG}"

if [[ $hpccRunning -ne 0 ]]
then
    #sudo /etc/init.d/hpcc-init status | cut -s -d' '  -f1
    echo "Stop HPCC System..."
    res=$(sudo /etc/init.d/hpcc-init stop |grep 'still')
    # If the result is "Service dafilesrv, mydafilesrv is still running."
    if [[ -n $res ]]
    then
	WriteLog "result:${res}" "${PERF_TEST_LOG}"
        echo $res
        sudo service dafilesrv stop
    fi
else
    echo "HPCC System already stopped."
    WriteLog "HPCC System already stopped." "${PERF_TEST_LOG}"
fi


#
#-----------------------------------------------------------------------------
#
# End of Performance test
#

WriteLog "End of Performance test" "${PERF_TEST_LOG}"
