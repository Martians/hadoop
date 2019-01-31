#!/bin/bash

## 配置
:<<COMMENT
==============================================
echo "
export HOST1=100.1.1.10
export HOST2=100.1.1.11
export HOST3=100.1.1.12
export DISK1=/mnt/disk1
export DISK2=/mnt/disk2" >> ~/.bashrc 
echo "export LOCAL=1" >> ~/.bashrc 
==============================================
echo  "export TESTS=1
export SOURC=/source/nosql
export HOST1=192.168.10.111
export HOST2=192.168.10.112
export HOST3=192.168.10.113
export DISK1=/mnt/disk1
export DISK2=/mnt/disk2" >> ~/.bashrc 
#echo "export LOCAL=1" >> ~/.bashrc

source ~/.bashrc
sh /root/testing/deploy/cassandra/cassandra.install.sh
source ~/.bashrc
echo;
COMMENT

BASE_PATH=$(cd "$(dirname "$0")"; cd ..; pwd)
. $BASE_PATH/common/handle.sh

if [ ! $LOCAL ] || [ ! $HOST1 ] || [ ! $HOST2 ] || [ ! $HOST3 ]; then
	echo "should config: HOST1 HOST2 HOST3; LOCAL=1"
	exit -1
else
	echo "HOST1: $HOST1"
	echo "HOST2: $HOST2"
	echo "HOST3: $HOST3"
	echo "LOCAL: $LOCAL"
fi

##################################################################################################
NAME=cassandra
DEST=/opt/cassandra

##################################################################################################
CONFIG_PATH=/opt/cassandra/conf
CONFIG_FILE=$CONFIG_PATH/cassandra.yaml
CLUSTER=test_cluster
SEEDS=$HOST1,$HOST2
LOCAL=$(dyn_var HOST$LOCAL)
LISTEN=$LOCAL
RPC=$LOCAL

# DISKS=$(comb_wrapper DISK ,)
# HOSTS=$HOST1:$MASTER_PORT,$HOST2:$MASTER_PORT,$HOST3:$MASTER_PORT
BIN_TOOL=$BASE_PATH/cassandra/cassandra
##################################################################################################
if [ -d $DEST ]; then
	echo "already installed ..."
else
	echo "install ..."
	install_package $NAME $DEST http://mirrors.hust.edu.cn/apache/cassandra/3.11.2/apache-cassandra-3.11.2-bin.tar.gz $SOURC
fi

cd $DEST
# 如果已经开启就立即关闭
sh $BIN_TOOL stop

##################################################################################################
echo "install depend ..."  
install_depend "java -version" 1.8 java-1.8.0-openjdk.x86_64


##################################################################################################
echo "clear data path ..."  
exec_wrapper_param DISK "" "/*" rm -rf
exec_wrapper DISK mkdir -p

##################################################################################################
echo "configure ..."
cp $CONFIG_FILE $CONFIG_FILE.old

sed -i "s/.*\(cluster_name: \).*/\1'$CLUSTER'/" $CONFIG_FILE
sed -i "s/\(- seeds: \).*/\1\"$SEEDS\"/" $CONFIG_FILE
sed -i "s/.*\(listen_address: \).*/\1\"$LISTEN\"/" $CONFIG_FILE
sed -i "s/.*\(^rpc_address: \).*/\1\"$RPC\"/" $CONFIG_FILE
#sed -i "s/.*\(experimental: \).*/\1true/" $CONFIG_FILE

## change disk config
sed -i "s/.*\(data_file_directories:\)/\1/" $CONFIG_FILE
disk_array=$(echo_wrapper DISK "\ \ - " "\n")
sed -i "/data_file_directories:/a$disk_array" $CONFIG_FILE
# DISK1中包含/，因此在sed使用|作为分隔符
sed  -i "s|.*\(commitlog_directory: \).*|\1 $DISK1/commitlog|" $CONFIG_FILE

## 增大超时时间
sed -i "s/\(read_request_timeout_in_ms: \).*/\160000/g" $CONFIG_FILE
sed -i "s/\(write_request_timeout_in_ms: \).*/\160000/g" $CONFIG_FILE
sed -i "s/\(request_timeout_in_ms: \).*/\160000/g" $CONFIG_FILE

## 设置batch的限制为50k
sed -i "s/\(batch_size_warn_threshold_in_kb: \).*/\150/g" $CONFIG_FILE

# 日志：取消输出到stdout
sed -i "/ref=\"STDOUT\"/d" $CONFIG_PATH/logback.xml

# 对外导出JMX
sed -i "/x$LOCAL_JMX\iaaaa/d" $CONFIG_PATH/cassandra-env.sh
sed -i "/x\$LOCAL_JMX/i LOCAL_JMX=no" $CONFIG_PATH/cassandra-env.sh 
sed -i "s/\(authenticate=\)true/\1false/" $CONFIG_PATH/cassandra-env.sh 
# 设置ip一致；或者确保 hostname -i 返回得到的ip就是LOCAL。通过修改/etc/hosts
sed -i "s/# \(.*java.rmi.server.hostname=\).*/\1$LOCAL\"/" $CONFIG_PATH/cassandra-env.sh 

echo "check $CONFIG_FILE"
cat $CONFIG_FILE | grep --color -e "cluster_name:" -e "- seeds:" -e "listen_address: " -e "^rpc_address: "

echo "check request time"P
cat $CONFIG_FILE | grep --color -e "^read_request_timeout_in_ms:" -e "^write_request_timeout_in_ms:" -e "^request_timeout_in_ms:"

echo "check data path"
cat $CONFIG_FILE | grep --color -e "data_file_directories:" -A 2 -e "commitlog_directory:" 

# ##################################################################################################
echo "add tool path"
chmod +x $BIN_TOOL
echo "PATH=\$PATH:$BASE_PATH/cassandra:$DEST/bin" >> ~/.bashrc
tool_link $BASE_PATH/cassandra/cassandra c

# ##################################################################################################
echo "start server"
source ~/.bashrc
$BIN_TOOL start

sleep 3
echo "cassandra status"
$BIN_TOOL status

