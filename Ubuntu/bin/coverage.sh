#!/bin/bash
clear 

COVERAGE_ROOT=~/coverage
TEST_ROOT=~/coverage
TEST_HOME=${TEST_ROOT}/HPCC-Platform/testing/regress
BUILD_HOME=~/build/CE/platform/build


# Clean system

echo ""
echo "Clean system"
[ ! -e $TEST_ROOT ] && mkdir -p $TEST_ROOT

rm -rf ${TEST_ROOT}/*
cd  ${TEST_ROOT}

echo ""
echo Un-install HPCC
rpm -qa | grep hpcc | grep -v grep |
while read hpcc_package
do
   echo $hpcc_package
   rpm -e $hpcc_package
done

rpm -qa | grep hpcc > /dev/null 2>&1
if [ $? -eq 0 ]
then
   touch  clean.failed
   exit
fi

# Build HPCC with coverage
cd ${BUILD_HOME}

echo ""
echo Copy patched hpcc_common.in.cov to initfiles/bash/etc/init.d/hpcc_common.in
cp ~/build/bin/hpcc_common.in.cov ../HPCC-Platform/initfiles/bash/etc/init.d/hpcc_common.in

cmake -DGENERATE_COVERAGE_INFO=ON -DCMAKE_BUILD_TYPE=Debug ../HPCC-Platform
make -j 8 
make package

# Install HPCC
echo ""
echo "Install HPCC-Platform"
rpm -i --nodeps ${BUILD_HOME}/hpccsystems-platform_community-with-plugins-4.3.0-trunk1Debug*.rpm

if [ $? -ne 0 ]
then
   echo "TestResult:FAILED" >> $TEST_ROOT/install.summary
   exit
else
   echo "TestResult:PASSED" >> $TEST_ROOT/install.summary
fi

echo ""
echo "Set up coverage environment"

find . -name "*.dir" -type d -exec chmod -R 777 {} \;

lcov --zerocounters --directory .

echo ""
echo Patch environment.conf file
cp /etc/HPCCSystems/environment.conf /etc/HPCCSystems/environment.conf-orig
echo "umask=0" >> /etc/HPCCSystems/environment.conf

echo ""
echo Start HPCC
service hpcc-init start

cd  ${TEST_ROOT}

# Get test from github
echo ""
echo "Get test from github"
git clone https://github.com/hpcc-systems/HPCC-Platform.git

# Prepare regression test
echo ""
echo "Prepare reqgression test"
logDir=/root/HPCCSystems-regression/log
[ ! -d $logDir ] && mkdir -p $logDir
rm -rf ${logDir}/*

libDir=/var/lib/HPCCSystems/regression
[ ! -d $libDir ] && mkdir  -p  $libDir
rm -rf ${libDir}/*

# Run test
echo ""
echo "Run reqgression test"
cd  $TEST_HOME

echo ""
echo "Copy patched regress for coverage"
cp ~/build/bin/regress.cov regress


./regress --suiteDir . list | grep -v "Cluster" |
while read cluster
do

  echo ""
  echo "./regress --suiteDir . run $cluster"
  ./regress run $cluster --pq -1
  cp ${logDir}/${cluster}*.log ${TEST_ROOT}/
  total=$(cat ${logDir}/${cluster}*.log | sed -n "s/^[[:space:]]*Queries:[[:space:]]*\([0-9]*\)[[:space:]]*$/\1/p")
  passed=$(cat ${logDir}/${cluster}*.log | sed -n "s/^[[:space:]]*Passing:[[:space:]]*\([0-9]*\)[[:space:]]*$/\1/p")
  failed=$(cat ${logDir}/${cluster}*.log | sed -n "s/^[[:space:]]*Failure:[[:space:]]*\([0-9]*\)[[:space:]]*$/\1/p")
  #[ $passed -gt 0 ] && passed="<span style=\"color:#298A08\">$passed</span>"
  #[ $failed -gt 0 ] && failed="<span style=\"color:#FF0000\">$passed</span>"
  echo "TestResult:Total:${total} passed:$passed failed:$failed" > ${TEST_ROOT}/${cluster}.summary

done

service hpcc-init stop

echo ""
echo "Generate coverage report"

cd $BUILD_HOME
lcov --capture --directory . --output-file $TEST_ROOT/hpcc_coverage.lcov > $TEST_ROOT/lcov.log 2>&1

genhtml --highlight --legend --ignore-errors source --output-directory $TEST_ROOT/hpcc_coverage $TEST_ROOT/hpcc_coverage.lcov > $TEST_ROOT/genhtml.log 2>&1

cd $TEST_ROOT

echo ""
echo "Generate coverage summary"

grep -i "coverage rate" -A3 ./genhtml.log > coverage.summary
echo "(This is an experimental result, yet. Use it carefully.)" >> coverage.summary

cp coverage.summary /root/test/

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

echo ""
echo "End."


