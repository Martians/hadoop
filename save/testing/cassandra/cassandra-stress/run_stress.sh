#!/bin/bash

# command：https://docs.datastax.com/en/cassandra/3.0/cassandra/tools/toolsCStress.html
# example: https://github.com/apache/cassandra/tree/trunk/tools


# 1. 模式
# 	read、write、mixed、user、print（查看分布）

# 2. 子选项
# 	# -pop：unique key分布方式、或者 本机分配的数据范围（多机并行测试）
# 	# -sample：衡量延迟的采样
# 	# -schema：指定keyspace、压缩方式、副本数
# 	# -col：列定义、取值分布、大续爱
# 	-rate：线程数、每秒请求数限制、每秒固定请求
# 	-node
# 	-log：时间间隔、文件名、级别
# 	-graph

# 3. 参数
# 	c1：一致性级别、clustering=DIST(?)？
# 	duration：持续时间
# 	no-warmup、profile
# 	truncate：never, once, always
# 	n：个数(n>? nn<?)
#	threads

:<<COMMENT
echo '
	PATH=$PATH:/mnt/disk/cassandra/tools/bin
' >> ~/.bashrc
source ~/.bashrc
COMMENT
#########################################################################################
HOST=127.0.0.1

#########################################################################################
for var in $*; do
	if [[ $var == "clear" ]]; then
		echo "drop keyspace"
		cqlsh $HOST -e "drop keyspace if exists stresscql;"
		exit
	fi
done

index=$1
shift

# usage：
#	命令的顺序不能改变
#	run_stress.sh 1 n=10000000
set -x
cassandra-stress user profile=`ls $index*` ops\(insert=1\) $* -rate threads=100 -node $HOST #-graph file=test.html 
