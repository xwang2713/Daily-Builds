#!/bin/bash

DATE=$(date "+%Y-%m-%d_%H-%M-%S") 
DATE_SHORT=$(date "+%Y-%m-%d") 
HPCC_LOG_DIR=/var/log/HPCCSystems
HPCC_BINARY_DIR=/var/lib/HPCCSystems
HPCC_BUILD_DIR=/root/build/CE/platform/build
OBT_LOG_DIR=/root/build/bin
TEST_LOG_DIR=/root/HPCCSystems-regression

ARCHIVE_TARGET_DIR=/root/HPCCSystems-log-archive

TEST_LOG_SUBDIRS=('log' 'archives' 'results')

clear

if [ ! -d $ARCHIVE_TARGET_DIR ]
then
	mkdir $ARCHIVE_TARGET_DIR
fi

FULL_ARCHIVE_TARGET_DIR=${ARCHIVE_TARGET_DIR}/$DATE_SHORT

if [ ! -d $FULL_ARCHIVE_TARGET_DIR ]
then
	mkdir $FULL_ARCHIVE_TARGET_DIR
fi


ARCHIVE_NAME=''
if [ "$1." = "." ]
then
    ARCHIVE_NAME='Logs-archive'
else
    ARCHIVE_NAME=$1
fi

ARCHIVE_NAME=${ARCHIVE_NAME}'-'${DATE}

echo 'Archive: '$ARCHIVE_NAME


#
# --------------------------------
# Archive /tmp/build.log if exists
#

if [ -f /tmp/build.log ]
then
	echo "Archive content of /tmp/build.log"
	echo 'Archive content of /tmp/build.log' >> ${FULL_ARCHIVE_TARGET_DIR}/${ARCHIVE_NAME}.log
	echo '-----------------------------------------------------------' >> ${FULL_ARCHIVE_TARGET_DIR}/${ARCHIVE_NAME}.log
	zip ${FULL_ARCHIVE_TARGET_DIR}/${ARCHIVE_NAME}  /tmp/build.log >> ${FULL_ARCHIVE_TARGET_DIR}/${ARCHIVE_NAME}.log 
	echo '' >> ${FULL_ARCHIVE_TARGET_DIR}/${ARCHIVE_NAME}.log
fi

#
# --------------------------------
# Archive logs from OBT_LOG_DIR
#
echo Archive content of ${OBT_LOG_DIR}
echo 'Archive content of '${OBT_LOG_DIR} >> ${FULL_ARCHIVE_TARGET_DIR}/${ARCHIVE_NAME}.log
echo '-----------------------------------------------------------' >> ${FULL_ARCHIVE_TARGET_DIR}/${ARCHIVE_NAME}.log
zip ${FULL_ARCHIVE_TARGET_DIR}/${ARCHIVE_NAME}  ${OBT_LOG_DIR}/obt-*.log >> ${FULL_ARCHIVE_TARGET_DIR}/${ARCHIVE_NAME}.log 
echo '' >> ${FULL_ARCHIVE_TARGET_DIR}/${ARCHIVE_NAME}.log


#
# --------------------------------
# Archive logs from HPCC_BUILD_DIR
#
echo Archive content of ${HPCC_BUILD_DIR}
echo 'Archive content of '${HPCC_BUILD_DIR} >> ${FULL_ARCHIVE_TARGET_DIR}/${ARCHIVE_NAME}.log
echo '-----------------------------------------------------------' >> ${FULL_ARCHIVE_TARGET_DIR}/${ARCHIVE_NAME}.log
zip ${FULL_ARCHIVE_TARGET_DIR}/${ARCHIVE_NAME}  ${HPCC_BUILD_DIR}/git_2days_log >> ${FULL_ARCHIVE_TARGET_DIR}/${ARCHIVE_NAME}.log 
zip ${FULL_ARCHIVE_TARGET_DIR}/${ARCHIVE_NAME}  ${HPCC_BUILD_DIR}/*.log >> ${FULL_ARCHIVE_TARGET_DIR}/${ARCHIVE_NAME}.log 
echo '' >> ${FULL_ARCHIVE_TARGET_DIR}/${ARCHIVE_NAME}.log

#
# --------------------------------
# Archive logs from HPCC_LOG_DIR
#
echo Archive content of ${HPCC_LOG_DIR}
echo 'Archive content of '${HPCC_LOG_DIR} >> ${FULL_ARCHIVE_TARGET_DIR}/${ARCHIVE_NAME}.log
echo '-----------------------------------------------------------' >> ${FULL_ARCHIVE_TARGET_DIR}/${ARCHIVE_NAME}.log
zip ${FULL_ARCHIVE_TARGET_DIR}/${ARCHIVE_NAME} -r ${HPCC_LOG_DIR} >> ${FULL_ARCHIVE_TARGET_DIR}/${ARCHIVE_NAME}.log 
echo '' >> ${FULL_ARCHIVE_TARGET_DIR}/${ARCHIVE_NAME}.log


#
# --------------------------------
# Archive content of TEST_LOG_DIR
#
echo Archive content of ${TEST_LOG_DIR}
echo 'Archive content of '${TEST_LOG_DIR} >> ${FULL_ARCHIVE_TARGET_DIR}/${ARCHIVE_NAME}.log
echo '-----------------------------------------------------------' >> ${FULL_ARCHIVE_TARGET_DIR}/${ARCHIVE_NAME}.log
echo '' >> ${FULL_ARCHIVE_TARGET_DIR}/${ARCHIVE_NAME}.log


for i in ${TEST_LOG_SUBDIRS[@]}
do 
    echo Archive content of ${TEST_LOG_DIR}/$i
    echo "  Archive content of :"$i >> ${FULL_ARCHIVE_TARGET_DIR}/${ARCHIVE_NAME}.log
    echo "  ------------------------------------" >> ${FULL_ARCHIVE_TARGET_DIR}/${ARCHIVE_NAME}.log

    zip ${FULL_ARCHIVE_TARGET_DIR}/${ARCHIVE_NAME} -r ${TEST_LOG_DIR}/$i/ >> ${FULL_ARCHIVE_TARGET_DIR}/${ARCHIVE_NAME}.log
    echo '' >> ${FULL_ARCHIVE_TARGET_DIR}/${ARCHIVE_NAME}.log

done


#
# --------------------------------
# Archive core files if generated
#

cores=($(find ${HPCC_BINARY_DIR} -name 'core' -type f))

if [ ${#cores[@]} -ne 0 ]
then
    echo 'Archive '${#cores[*]}' core file(s) from '${HPCC_BINARY_DIR}
    echo 'Archive '${#cores[*]}' core file(s) from '${HPCC_BINARY_DIR} >> ${FULL_ARCHIVE_TARGET_DIR}/${ARCHIVE_NAME}.log
    echo '-----------------------------------------------------------' >> ${FULL_ARCHIVE_TARGET_DIR}/${ARCHIVE_NAME}.log
    echo '' >> ${FULL_ARCHIVE_TARGET_DIR}/${ARCHIVE_NAME}.log
fi
 
for c in ${cores[@]}
do 
    echo $c
    sudo zip ${FULL_ARCHIVE_TARGET_DIR}/${ARCHIVE_NAME} $c >> ${FULL_ARCHIVE_TARGET_DIR}/${ARCHIVE_NAME}.log
done


#
# --------------------------------
# End of archiving process
#

echo '' >> ${FULL_ARCHIVE_TARGET_DIR}/${ARCHIVE_NAME}.log
echo 'End of archive' >> ${FULL_ARCHIVE_TARGET_DIR}/${ARCHIVE_NAME}.log
echo '-----------------------------------------------------------' >> ${FULL_ARCHIVE_TARGET_DIR}/${ARCHIVE_NAME}.log


