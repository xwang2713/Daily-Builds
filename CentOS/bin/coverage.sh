#!/bin/bash
clear 

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

COVERAGE_ROOT=~/coverage
TEST_ROOT=~/build/CE/platform
TEST_HOME=${TEST_ROOT}/HPCC-Platform/testing/regress
BUILD_HOME=~/build/CE/platform/build
BUILD_LOG=${COVERAGE_ROOT}/build_log
LONG_DATE=$(date "+%Y-%m-%d_%H-%M-%S")
COVERAGE_LOG_FILE=${BUILD_HOME}/coverage-${LONG_DATE}.log

#
#----------------------------------------------------
#
# Start Coverage process
#

WriteLog "Coverage test started" "${COVERAGE_LOG_FILE}"


#
#----------------------------------------------------
#
# Clean-up
#

WriteLog "Clean system" "${COVERAGE_LOG_FILE}"
echo ""
echo "Clean system"
echo "Clean system" > ${BUILD_LOG} 2>&1

[ ! -e $COVERAGE_ROOT ] && mkdir -p $COVERAGE_ROOT

rm -rf ${COVERAGE_ROOT}/*
#cd  ${COVERAGE_ROOT}

#----------------------------------------------------
#
# Uninstall HPCC
#

WriteLog "Uninstall HPCC-Platform" "${COVERAGE_LOG_FILE}"

echo ""
echo Un-install HPCC
echo "Un-install HPCC" >> ${BUILD_LOG} 2>&1

/opt/HPCCSystems/sbin/complete-uninstall.sh

#rpm -qa | grep hpcc | grep -v grep |
#while read hpcc_package
#do
#   echo $hpcc_package
#   echo $hpcc_package  >> ${BUILD_LOG} 2>&1
#   WriteLog "HPCC package:"${hpcc_package} "${COVERAGE_LOG_FILE}"
#   rpm -e $hpcc_package
#done
#
#rpm -qa | grep hpcc > /dev/null 2>&1
#if [ $? -eq 0 ]
#then
#   touch  clean.failed
#   exit
#fi


# --------------------------------------------------------------
#
# Build HPCC with coverage
#

WriteLog "Build HPCC with coverage" "${COVERAGE_LOG_FILE}"

cd ${BUILD_HOME}

WriteLog "cmake -DGENERATE_COVERAGE_INFO=ON -DCMAKE_BUILD_TYPE=Release ../HPCC-Platform -DUSE_LIBXSLT=ON -DXALAN_LIBRARIES=" "${COVERAGE_LOG_FILE}"

cmake -DGENERATE_COVERAGE_INFO=ON -DCMAKE_BUILD_TYPE=Release ../HPCC-Platform -DUSE_LIBXSLT=ON -DXALAN_LIBRARIES= 

make -j 8 
make package


#----------------------------------------------------
#
# Install HPCC
#

WriteLog "Install HPCC-Platform" "${COVERAGE_LOG_FILE}"

echo ""
echo "Install HPCC-Platform"
echo "Install HPCC-Platform"  >> ${BUILD_LOG} 2>&1

rpm -i --nodeps ${BUILD_HOME}/hpccsystems-platform_community*.rpm

if [ $? -ne 0 ]
then
   echo "TestResult:FAILED" >> $TEST_ROOT/install.summary
   echo "TestResult:FAILED" >> ${BUILD_LOG} 2>&1
   WriteLog "Install HPCC-Platform FAILED" "${COVERAGE_LOG_FILE}"

   exit
else
   echo "TestResult:PASSED" >> $TEST_ROOT/install.summary
   echo "TestResult:PASSED" >> ${BUILD_LOG} 2>&1
   WriteLog "Install HPCC-Platform PASSED" "${COVERAGE_LOG_FILE}"

fi


# --------------------------------------------------------------
#
# Set up coverage environment
#

WriteLog "Set up coverage environment" "${COVERAGE_LOG_FILE}"

echo ""
echo "Set up coverage environment"
echo "Set up coverage environment" >> ${BUILD_LOG} 2>&1


find . -name "*.dir" -type d -exec chmod -R 777 {} \;

lcov --zerocounters --directory .

echo ""
echo "Patch environment.conf file"
echo "Patch environment.conf file" >> ${BUILD_LOG} 2>&1

cp /etc/HPCCSystems/environment.conf /etc/HPCCSystems/environment.conf-orig
echo "umask=0" >> /etc/HPCCSystems/environment.conf


# --------------------------------------------------------------
#
# Start HPCC Systems
#

WriteLog "Start HPCC Systems" "${COVERAGE_LOG_FILE}"

echo ""
echo "Start HPCC"
echo "Start HPCC" >> ${BUILD_LOG} 2>&1

service hpcc-init start


# --------------------------------------------------------------
#
# Prepare regression test in coverage enviromnment
#

WriteLog "Prepare regression test in coverage enviromnment" "${COVERAGE_LOG_FILE}"

echo ""
echo "Prepare reqgression test"
echo "Prepare reqgression test" >> ${BUILD_LOG} 2>&1

logDir=/root/HPCCSystems-regression/log
[ ! -d $logDir ] && mkdir -p $logDir
rm -rf ${logDir}/*

libDir=/var/lib/HPCCSystems/regression
[ ! -d $libDir ] && mkdir  -p  $libDir
rm -rf ${libDir}/*

#
# --------------------------------------------------------------
#
# Run test
#

WriteLog "Run regression test" "${COVERAGE_LOG_FILE}"

echo ""
echo "Run reqgression test"
echo "Run reqgression test" >> ${BUILD_LOG} 2>&1

cd  $TEST_HOME


WriteLog "Set and export coverage variable for create coverage build" "${COVERAGE_LOG_FILE}"

echo ""
echo "Set and export coverage variable for create coverage build"
echo "Set and export coverage variable for create coverage build" >> ${BUILD_LOG} 2>&1

coverage=1
export coverage

# ----------------------------------------------------
#
#From ecl-test v0.15 the 'setup' removed from clusters and it becomes separated sub command (See: HPCC-11071)
#
# Setup should run on all clusters

WriteLog "Setup phase" "${COVERAGE_LOG_FILE}"

./ecl-test list | grep -v "Cluster" |
while read cluster
do

  echo ""

  WriteLog "./ecl-test run --target $cluster" "${COVERAGE_LOG_FILE}"

  echo "./ecl-test run --target $cluster"
  ./ecl-test setup --target $cluster

  # --------------------------------------------------
  # temporarly fix for wrongly generated setup logfile

  for f in $(ls -1 ${logDir}/${cluster}.*.log)
     do mv $f ${logDir}/setup_${cluster}.${f#*.}
  done

  for f in $(ls -1 ${logDir}/${cluster}-exclusion.*.log)
     do mv $f ${logDir}/setup_${cluster}-exclusion.${f#*.}
  done

  # -------------------------------------------------

  #cp ${logDir}/thor.*.log ${COVERAGE_ROOT}/
  cp ${logDir}/setup_${cluster}*.log ${COVERAGE_ROOT}/

  total=$(cat ${logDir}/setup_${cluster}*.log | sed -n "s/^[[:space:]]*Queries:[[:space:]]*\([0-9]*\)[[:space:]]*$/\1/p")
  passed=$(cat ${logDir}/setup_${cluster}*.log | sed -n "s/^[[:space:]]*Passing:[[:space:]]*\([0-9]*\)[[:space:]]*$/\1/p")
  failed=$(cat ${logDir}/setup_${cluster}*.log | sed -n "s/^[[:space:]]*Failure:[[:space:]]*\([0-9]*\)[[:space:]]*$/\1/p")

  #[ $passed -gt 0 ] && passed="<span style=\"color:#298A08\">$passed</span>"
  #[ $failed -gt 0 ] && failed="<span style=\"color:#FF0000\">$passed</span>"

  echo ${cluster}" Setup Result:Total:${total} passed:$passed failed:$failed" >> ${COVERAGE_ROOT}/setup.summary 
  echo ${cluster}" Setup Result:Total:${total} passed:$passed failed:$failed" >> ${BUILD_LOG} 2>&1

  WriteLog "${cluster} Setup Result:Total:${total} passed:$passed failed:$failed" "${COVERAGE_LOG_FILE}"

done

# -----------------------------------------------------
#
# Run tests
#

WriteLog "Regression Suite phase" "${COVERAGE_LOG_FILE}"

./ecl-test list | grep -v "Cluster" |
while read cluster
do

  echo ""
  echo "./ecl-test run --target $cluster"
  echo "./ecl-test run --target $cluster" >> ${BUILD_LOG} 2>&1
  WriteLog "./ecl-test run --target $cluster" "${COVERAGE_LOG_FILE}"

  ./ecl-test run --target $cluster 

  cp ${logDir}/${cluster}*.log ${COVERAGE_ROOT}/

  total=$(cat ${logDir}/${cluster}*.log | sed -n "s/^[[:space:]]*Queries:[[:space:]]*\([0-9]*\)[[:space:]]*$/\1/p")
  passed=$(cat ${logDir}/${cluster}*.log | sed -n "s/^[[:space:]]*Passing:[[:space:]]*\([0-9]*\)[[:space:]]*$/\1/p")
  failed=$(cat ${logDir}/${cluster}*.log | sed -n "s/^[[:space:]]*Failure:[[:space:]]*\([0-9]*\)[[:space:]]*$/\1/p")

  #[ $passed -gt 0 ] && passed="<span style=\"color:#298A08\">$passed</span>"
  #[ $failed -gt 0 ] && failed="<span style=\"color:#FF0000\">$passed</span>"

  echo "TestResult:Total:${total} passed:$passed failed:$failed" > ${COVERAGE_ROOT}/${cluster}.summary
  echo "TestResult:Total:${total} passed:$passed failed:$failed" >> ${BUILD_LOG} 2>&1

  WriteLog "TestResult:Total:${total} passed:$passed failed:$failed" "${COVERAGE_LOG_FILE}"

done

service hpcc-init stop

#
# --------------------------------------------------------------
#
# Generate coverage report
#

WriteLog "Generate coverage report" "${COVERAGE_LOG_FILE}"

echo ""
echo "Generate coverage report"
echo "Generate coverage report"  >> ${BUILD_LOG} 2>&1

cd $BUILD_HOME
lcov --capture --directory . --output-file $COVERAGE_ROOT/hpcc_coverage.lcov > $COVERAGE_ROOT/lcov.log 2>&1

genhtml --highlight --legend --ignore-errors source --output-directory $COVERAGE_ROOT/hpcc_coverage $COVERAGE_ROOT/hpcc_coverage.lcov > $COVERAGE_ROOT/genhtml.log 2>&1

cd $COVERAGE_ROOT

WriteLog "Generate coverage report summary" "${COVERAGE_LOG_FILE}"

echo ""
echo "Generate coverage summary"
echo "Generate coverage summary" >> ${BUILD_LOG} 2>&1

grep -i "coverage rate" -A3 ./genhtml.log > coverage.summary
echo "(This is an experimental result, yet. Use it carefully.)" >> coverage.summary

cp coverage.summary /root/test/


# --------------------------------------------------------------
# Uninstall HPCC
#echo ""
#echo "Uninstall HPCC-Platform"
#uninstallFailed=FALSE
#hpccPackageName=$(rpm -qa | grep hpcc)
#rpm -e $hpccPackageName  >  uninstall.log 2>&1
#[ $? -ne 0 ] && uninstallFailed=TRUE
#
#rpm -qa | grep hpcc  > /dev/null 2>&1
#[ $? -eq 0 ] && uninstallFailed=TRUE
#
#
#if [ "$uninstallFailed" = "TRUE" ]
#then
#   echo "TestResult:FAILED" >> uninstall.summary
#else
#   echo "TestResult:PASSED" >> uninstall.summary
#fi
#


#-----------------------------------------------------------------------------
#
# End of Coverage process
#
#

WriteLog "End of Coverage process" "${REGRESS_LOG_FILE}"

echo ""
echo "End."
echo "End." >> ${BUILD_LOG} 2>&1


