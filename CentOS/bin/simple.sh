#!/bin/bash


cd /root/build/bin
echo "pwd:$(pwd)"

#
#------------------------------
#
# Imports (settings, functions)
#

# Git branch settings

. ./settings.sh

# WriteLog() function

. ./root/build/bin/timestampLogger.sh

#
#------------------------------
#
# Constants
#

SHORT_DATE=$(date "+%Y-%m-%d")
LONG_DATE=$(date "+%Y-%m-%d_%H-%M-%S") 
BUILD_DIR=/root/build
RELEASE_BASE=5.0
RELEASE=
STAGING_DIR=/tmount/data2/nightly_builds/HPCC/$RELEASE_BASE
BUILD_SYSTEM=centos_6_x86_64
BUILD_TYPE=CE/platform
OBT_LOG_DIR=${BUILD_DIR}/bin
OBT_LOG_FILE=${BUILD_DIR}/bin/obt-${LONG_DATE}.log

#
#----------------------------------------------------
#
# Start Overnight Build and Test process
#

WriteLog "OBT started" "${OBT_LOG_FILE}"

#
#----------------------------------------------------
#
# Clean-up, git repo clone and git submodule
#

WriteLog "Clean-up, git repo clone and git submodule" "${OBT_LOG_FILE}"

cd ${BUILD_DIR}/$BUILD_TYPE
rm -rf build HPCC-Platform
git clone https://github.com/hpcc-systems/HPCC-Platform.git
mkdir build
cd HPCC-Platform
git submodule update --init


#
#----------------------------------------------------
#
# We use branch which is set in settings.sh
#
WriteLog "We use branch which is set in settings.sh branch:${BRANCH_ID}" "${OBT_LOG_FILE}"


echo "git branch: "${BRANCH_ID}  > ../build/git_2days_log

echo "git checkout "${BRANCH_ID} >> ../build/git_2days_log
echo "git checkout "${BRANCH_ID}
res=$( git checkout ${BRANCH_ID} 2>&1 )
echo $res
echo $res >> ../build/git_2days_log
WriteLog "Result:${res}" "${OBT_LOG_FILE}"

echo "git remote -v:"  >> ../build/git_2days_log
git remote -v  >> ../build/git_2days_log

echo ""  >> ../build/git_2days_log
cat ${BUILD_DIR}/bin/gitlog.sh >> ../build/git_2days_log
${BUILD_DIR}/bin/gitlog.sh >> ../build/git_2days_log


#
#--------------------------------------------------
#
# Build it
#
WriteLog "Build it..." "${OBT_LOG_FILE}"

cd ../build

CURRENT_DATE=$( date +%Y-%m-%d_%H-%M-%S)
echo "Start at "${CURRENT_DATE}
echo "Start at "${CURRENT_DATE} > build.log 2>&1


${BUILD_DIR}/bin/build_pf.sh HPCC-Platform >> build.log 2>&1


make -j 8 package >> build.log 2>&1
if [ $? -ne 0 ] 
then
   echo "Build failed: build has errors " >> build.log
   buildResult=FAILED
else
   ls -l hpcc*.rpm >/dev/null 2>&1
   if [ $? -ne 0 ] 
   then
      echo "Build failed: no rpm package found " >> build.log
      buildResult=FAILED
   else
      echo "Build succeed" >> build.log
      buildResult=SUCCEED
   fi
fi

CURRENT_DATE=$( date +%Y-%m-%d_%H-%M-%S)
echo "Build end at "${CURRENT_DATE}
echo "Build end at "${CURRENT_DATE} >> build.log 2>&1

TARGET_DIR=${STAGING_DIR}/${SHORT_DATE}/${BUILD_SYSTEM}/${BUILD_TYPE}

if [ ! -e "${TARGET_DIR}" ] 
then
   mkdir -p  $TARGET_DIR
   chmod 777 ${STAGING_DIR}/${SHORT_DATE}
fi

cp git_2days_log  $TARGET_DIR/
cp build.log  $TARGET_DIR/
cp hpcc*.rpm  $TARGET_DIR/
if [ "$buildResult" = "SUCCEED" ]
then
   echo "BuildResult:SUCCEED" >   $TARGET_DIR/build_summary
   WriteLog "BuildResult:SUCCEED" "${OBT_LOG_FILE}"
 
else
   echo "BuildResult:FAILED" >   $TARGET_DIR/build_summary
   WriteLog "BuildResult:FAILED" "${OBT_LOG_FILE}"

fi


#
#--------------------------------------------------
#
# Regression test
#

WriteLog "Execute Regression test" "${OBT_LOG_FILE}"

cd /root/build/bin
./regress.sh

WriteLog "Copy regression test logs" "${OBT_LOG_FILE}"

mkdir -p   ${TARGET_DIR}/test
cp /root/test/*.log   ${TARGET_DIR}/test/
cp /root/test/*.summary   ${TARGET_DIR}/test/


# Remove old builds
${BUILD_DIR}/bin/clean_builds.sh

WriteLog "Send Email notification about Regression test" "${OBT_LOG_FILE}"

# Email Notify
./BuildNotification.py

WriteLog "Archive regression testing logs" "${OBT_LOG_FILE}"

./archiveLogs.sh regress

#-----------------------------------------------------------------------------
#
# Coverage
# Placed here to avoid any disturbance to regression test execution and result handling

WriteLog "Execute Coverage test" "${OBT_LOG_FILE}"


cd /root/build/bin

./coverage.sh
cp /root/test/coverage.summary   ${TARGET_DIR}/test/

WriteLog "Archive coverage testing logs" "${OBT_LOG_FILE}"

./archiveLogs.sh coverage

#-----------------------------------------------------------------------------
#
# Performance
# Placed here to avoid any disturbance to regression test execution and result handling

WriteLog "Execute Performance test" "${OBT_LOG_FILE}"

cd /root/build/bin

./perftest.sh

cp -u /root/HPCCSystems-regression/log/*.*   ${TARGET_DIR}/test/


WriteLog "Send Email notification about Performance test" "${OBT_LOG_FILE}"

cd /root/build/bin

./ReportPerfTestResult.py


#-----------------------------------------------------------------------------
#
# End of OBT
#

WriteLog "End of OBT" "${OBT_LOG_FILE}"

./archiveLogs.sh obt
