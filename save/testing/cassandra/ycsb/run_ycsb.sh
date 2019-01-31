#!/bin/bash

# https://github.com/brianfrankcooper/YCSB/wiki/Core-Properties

## 1) 运行内容
#	load: bin/ycsb load cassandra-cql -P cassandra.dat -s > load.log
#	read: bin/ycsb run cassandra-cql -P cassandra.dat -P ca_read.dat -s > run.log

## 2) 运行参数
# 	-threads 10
#	-target 
## 3) 后台运行
# 	nohup bin/ycsb run cassandra2-cql -s -threads 200 -P ...  > run.out 2> run.err &


# Usage:
#	run_ycsb.sh 0
#	run_ycsb.sh 1
#	run_ycsb.sh 1 -threads

:<<COMMENT
echo '
	PATH=$PATH:/mnt/disk/ycsb/bin
' >> ~/.bashrc
source ~/.bashrc
COMMENT

HOST=127.0.0.1
###################################################################
index=$1
shift

cqlsh $HOST -f import.cql
ycsb load cassandra-cql -P base.dat -P `ls $index*` -s $* > load.log
