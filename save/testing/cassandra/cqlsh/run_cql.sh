#!/bin/bash

echo "use table: example.test"

FILE=/var/lib/ceph/osd/ceph-18/data/93_col_01.csv
set -x

:<<COMMENT
echo '
	PATH=$PATH:/mnt/disk/cassandra/tools/bin
' >> ~/.bashrc
source ~/.bashrc
COMMENT

##########################################################################################
HOST=100.1.1.10

cqlsh $HOST -f import.cql
# 	MAXINSERTERRORS=1：发现错误立即退出
#	NUMPROCESSES: 线程数
#	REPORTFREQUENCY：每秒输出
#	ERRFILE='/tmp/import.err'
cqlsh $HOST --request-timeout 50 -e "copy example.test from '$FILE' with NUMPROCESSES=100 and MAXINSERTERRORS=1 and HEADER=true and REPORTFREQUENCY=1;"

