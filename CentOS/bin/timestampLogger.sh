#!/bin/bash

WriteLog()
(
    TIMESTAMP=$( date +%Y-%m-%d_%H-%M-%S)
    echo ${TIMESTAMP}":"$1 >> $2
)
