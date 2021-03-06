#!/bin/bash
DATE=$(date "+%Y-%m-%d")
BUILD_DIR=/home/ubuntu/build
RELEASE_BASE=master
RELEASE=
STAGING_DIR=/tmount/data2/nightly_builds/HPCC/$RELEASE_BASE
BUILD_SYSTEM=ubuntu_12.04_amd64
BUILD_TYPE=CE/platform

cd ${BUILD_DIR}/$BUILD_TYPE
rm -rf build HPCC-Platform
git clone https://github.com/hpcc-systems/HPCC-Platform.git
mkdir build
cd HPCC-Platform

git submodule update --init

#
#----------------------------------------------------
#
# For a while we build and test candidate-5.0.0 branch
#

BRANCH_ID=candidate-5.0.0
echo "git branch: $BRANCH_ID"  > ../build/git_2days_log

echo "git checkout "$BRANCH_ID >> ../build/git_2days_log
echo "git checkout "$BRANCH_ID
res=$( git checkout $BRANCH_ID )
echo $res
echo $res >> ../build/git_2days_log

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
cd ../build

${BUILD_DIR}/bin/build_pf.sh HPCC-Platform

make package > build.log 2>&1
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

TARGET_DIR=${STAGING_DIR}/${DATE}/${BUILD_SYSTEM}/${BUILD_TYPE}

[ ! -e "${TARGET_DIR}" ] && mkdir -p  $TARGET_DIR

cp git_2days_log  $TARGET_DIR/
cp build.log  $TARGET_DIR/
cp hpcc*.rpm  $TARGET_DIR/
if [ "$buildResult" = "SUCCEED" ]
then
   echo "BuildResult:SUCCEED" >   $TARGET_DIR/build_summary
else
   echo "BuildResult:FAILED" >   $TARGET_DIR/build_summary
fi




exit






# Test
cd /home/ubuntu/build/bin
./regress.sh

./coverage.sh

mkdir -p   ${TARGET_DIR}/test
cp /root/test/*.log   ${TARGET_DIR}/test/
cp /root/test/*.summary   ${TARGET_DIR}/test/


# Remove old builds
${BUILD_DIR}/bin/clean_builds.sh

# Email Notify
./BuildNotification.py

