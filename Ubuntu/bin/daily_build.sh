#!/bin/bash
DATE=$(date "+%Y-%m-%d")
BUILD_DIR=/home/ubuntu/build
RELEASE_BASE=master
RELEASE=
STAGING_DIR=/tmount/data2/nightly_builds/HPCC/$RELEASE_BASE
BUILD_SYSTEM=ubuntu_12.04_amd64


#############################################################
#
# Build Community Platform
#
#############################################################
function build_platform()
{
   PRODUCT_CATEGORY=CE
   PRODUCT_NAME=platform
   SRC_DIR=HPCC-Platform
   REPO_URL=https://github.com/hpcc-systems/HPCC-Platform.git
   BUILD_SCRIPT=build_pf_ubuntu.sh
   PACKAGE_NAME_PREFIX=hpcc
   PACKAGE_FORMAT=deb


   BUILD_ROOT=${BUILD_DIR}/${PRODUCT_CATEGORY}/${PRODUCT_NAME} 
   [ ! -e ${BUILD_ROOT} ] && mkdir -p ${BUILD_ROOT} 
   cd ${BUILD_ROOT}
   rm -rf build $SRC_DIR

   #
   #----------------------------------------------------
   #
   # For a while we build and test candidate-5.0.0 branch
   #
   #BRANCH_ID=candidate-5.0.0
   #BRANCH_ID=closedown-5.0.x
   BRANCH_ID=master

   git clone $REPO_URL
   mkdir build
   cd  $SRC_DIR
   git submodule update --init

   echo "git branch: ${BRANCH_ID}"  > ../build/git_2days_log
   echo ""  >> ../build/git_2days_log

   echo "git remote -v:"  >> ../build/git_2days_log
   git remote -v  >> ../build/git_2days_log

   echo ""  >> ../build/git_2days_log
   cat ${BUILD_DIR}/bin/gitlog.sh >> ../build/git_2days_log
   ${BUILD_DIR}/bin/gitlog.sh >> ../build/git_2days_log

   cd ../build

   ${BUILD_DIR}/bin/${BUILD_SCRIPT}  $SRC_DIR

   make package > build.log 2>&1
   if [ $? -ne 0 ] 
   then
      echo "Build failed: build has errors " >> build.log
      buildResult=FAILED
   else
      ls -l ${PACKAGE_NAME_PREFIX}*.${PACKAGE_FORMAT} >/dev/null 2>&1
      if [ $? -ne 0 ] 
      then
         echo "Build failed: no ${PACKAGE_FORMAT} package found " >> build.log
         buildResult=FAILED
      else
         echo "Build succeed" >> build.log
         buildResult=SUCCEED
      fi
   fi

   TARGET_DIR=${STAGING_DIR}/${DATE}/${BUILD_SYSTEM}/${PRODUCT_CATEGORY}/${PRODUCT_NAME} 

   if [ ! -e "${TARGET_DIR}" ] 
   then
       mkdir -p  $TARGET_DIR
       chmod 777 ${STAGING_DIR}/${DATE}
   fi

   cp git_2days_log  $TARGET_DIR/
   cp build.log  $TARGET_DIR/
   cp ${PACKAGE_NAME_PREFIX}*.${PACKAGE_FORMAT} $TARGET_DIR/
   if [ "$buildResult" = "SUCCEED" ]
   then
      echo "BuildResult:SUCCEED" >   $TARGET_DIR/build_summary
   else
      echo "BuildResult:FAILED" >   $TARGET_DIR/build_summary
   fi
}

#############################################################
#
# Build Ganglia-monitoring
#
#############################################################
function build_ganglia_monitoring()
{
   PRODUCT_CATEGORY=CE
   PRODUCT_NAME=ganglia-monitoring
   SRC_DIR=ganglia-monitoring
   REPO_URL=https://github.com/hpcc-systems/ganglia-monitoring.git
   #BUILD_SCRIPT=build_pf_ubuntu.sh
   PACKAGE_NAME_PREFIX=hpcc
   PACKAGE_FORMAT=deb


   BUILD_ROOT=${BUILD_DIR}/${PRODUCT_CATEGORY}/${PRODUCT_NAME} 
   [ ! -e ${BUILD_ROOT} ] && mkdir -p ${BUILD_ROOT} 
   cd ${BUILD_ROOT}
   rm -rf build $SRC_DIR
   git clone $REPO_URL
   mkdir build
   cd  $SRC_DIR
   echo "git remote -v:"  > ../build/git_2days_log
   git remote -v  >> ../build/git_2days_log

   echo ""  >> ../build/git_2days_log
   echo "git branch: $(git branch)"  >> ../build/git_2days_log

   echo ""  >> ../build/git_2days_log
   cat ${BUILD_DIR}/bin/gitlog.sh >> ../build/git_2days_log
   ${BUILD_DIR}/bin/gitlog.sh >> ../build/git_2days_log

   cd ../build

   cmake  ../$SRC_DIR

   make package > build.log 2>&1
   if [ $? -ne 0 ] 
   then
      echo "Build failed: build has errors " >> build.log
      buildResult=FAILED
   else
      ls -l ${PACKAGE_NAME_PREFIX}*.${PACKAGE_FORMAT} >/dev/null 2>&1
      if [ $? -ne 0 ] 
      then
         echo "Build failed: no ${PACKAGE_FORMAT} package found " >> build.log
         buildResult=FAILED
      else
         echo "Build succeed" >> build.log
         buildResult=SUCCEED
      fi
   fi

   TARGET_DIR=${STAGING_DIR}/${DATE}/${BUILD_SYSTEM}/${PRODUCT_CATEGORY}/${PRODUCT_NAME} 

   [ ! -e "${TARGET_DIR}" ] && mkdir -p  $TARGET_DIR

   cp git_2days_log  $TARGET_DIR/
   cp build.log  $TARGET_DIR/
   cp ${PACKAGE_NAME_PREFIX}*.${PACKAGE_FORMAT} $TARGET_DIR/
   if [ "$buildResult" = "SUCCEED" ]
   then
      echo "BuildResult:SUCCEED" >   $TARGET_DIR/build_summary
   else
      echo "BuildResult:FAILED" >   $TARGET_DIR/build_summary

   fi
}

#############################################################
#
# Build Nagios-monitoring
#
#############################################################
function build_nagios_monitoring()
{
   PRODUCT_CATEGORY=CE
   PRODUCT_NAME=nagios-monitoring
   PACKAGE_NAME_PREFIX=hpcc
   PACKAGE_FORMAT=deb

   BUILD_ROOT=${BUILD_DIR}/${PRODUCT_CATEGORY}/${PRODUCT_NAME} 
   [ ! -e ${BUILD_ROOT} ] && mkdir -p ${BUILD_ROOT} 
   cd ${BUILD_ROOT}


   SRC_DIR=HPCC-Platform
   REPO_URL=https://github.com/hpcc-systems/HPCC-Platform.git
   rm -rf $SRC_DIR
   git clone $REPO_URL


   SRC_DIR=nagios-monitoring
   REPO_URL=https://github.com/hpcc-systems/nagios-monitoring.git
   rm -rf $SRC_DIR
   git clone $REPO_URL

   rm -rf build 
   mkdir build
   cd  $SRC_DIR
   echo "git remote -v:"  > ../build/git_2days_log
   git remote -v  >> ../build/git_2days_log

   echo ""  >> ../build/git_2days_log
   echo "git branch: $(git branch)"  >> ../build/git_2days_log

   echo ""  >> ../build/git_2days_log
   cat ${BUILD_DIR}/bin/gitlog.sh >> ../build/git_2days_log
   ${BUILD_DIR}/bin/gitlog.sh >> ../build/git_2days_log

   cd ../build

   cmake  ../$SRC_DIR

   make package > build.log 2>&1
   if [ $? -ne 0 ] 
   then
      echo "Build failed: build has errors " >> build.log
      buildResult=FAILED
   else
      ls -l ${PACKAGE_NAME_PREFIX}*.${PACKAGE_FORMAT} >/dev/null 2>&1
      if [ $? -ne 0 ] 
      then
         echo "Build failed: no ${PACKAGE_FORMAT} package found " >> build.log
         buildResult=FAILED
      else
         echo "Build succeed" >> build.log
         buildResult=SUCCEED
      fi
   fi

   TARGET_DIR=${STAGING_DIR}/${DATE}/${BUILD_SYSTEM}/${PRODUCT_CATEGORY}/${PRODUCT_NAME} 

   [ ! -e "${TARGET_DIR}" ] && mkdir -p  $TARGET_DIR

   cp git_2days_log  $TARGET_DIR/
   cp build.log  $TARGET_DIR/
   cp ${PACKAGE_NAME_PREFIX}*.${PACKAGE_FORMAT} $TARGET_DIR/
   if [ "$buildResult" = "SUCCEED" ]
   then
      echo "BuildResult:SUCCEED" >   $TARGET_DIR/build_summary
   else
      echo "BuildResult:FAILED" >   $TARGET_DIR/build_summary

   fi
}

#############################################################
#
# Build VM 64bit
#
#############################################################
function build_vm()
{
   PRODUCT_CATEGORY=CE
   PRODUCT_NAME=vm
   SRC_DIR=vm
   PACKAGE_NAME_PREFIX=hpcc
   PACKAGE_FORMAT=ova
   TEMPLATE_DIR=${BUILD_DIR}/bin/vm/template
   PLATFORM_DIR=${STAGING_DIR}/${DATE}/${BUILD_SYSTEM}/${PRODUCT_CATEGORY}/platform
   GM_DIR=${STAGING_DIR}/${DATE}/${BUILD_SYSTEM}/${PRODUCT_CATEGORY}/ganglia-monitoring
   NM_DIR=${STAGING_DIR}/${DATE}/${BUILD_SYSTEM}/${PRODUCT_CATEGORY}/nagios-monitoring
   TARGET_DIR=${STAGING_DIR}/${DATE}/${BUILD_SYSTEM}/${PRODUCT_CATEGORY}/${PRODUCT_NAME} 

   ssh vmadmin@10.176.152.30 -C "~/nightly_build/bin/build_vm.sh > /tmp/build_vm.log"
}

#############################################################
#
# MAIN
#
#############################################################
build_platform
build_ganglia_monitoring
build_nagios_monitoring
build_vm

echo "Done"

exit






## Test
#cd /home/ubuntu/build/bin
#./regress.sh
#
#./coverage.sh
#
#mkdir -p   ${TARGET_DIR}/test
#cp /root/test/*.log   ${TARGET_DIR}/test/
#cp /root/test/*.summary   ${TARGET_DIR}/test/
#
#
## Remove old builds
#${BUILD_DIR}/bin/clean_builds.sh
#
## Email Notify
#./BuildNotification.py

