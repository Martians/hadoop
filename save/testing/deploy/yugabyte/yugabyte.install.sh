#!/bin/bash
# https://docs.yugabyte.com/latest/deploy/multi-node-cluster/

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
echo "export LOCAL=1" >> ~/.bashrc 

source ~/.bashrc
sh /root/testing/deploy/yugabyte/yugabyte.install.sh
source ~/.bashrc
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
NAME=yugabyte
DEST=/opt/yugabyte

##################################################################################################
MASTER_PORT=7100
SERVER_PORT=9100
LOCAL_HOST=$(dyn_var HOST$LOCAL)

DISKS=$(comb_wrapper DISK ,)
HOSTS=$HOST1:$MASTER_PORT,$HOST2:$MASTER_PORT,$HOST3:$MASTER_PORT

##################################################################################################
if [ -d $DEST ]; then
	echo "already installed ..."
else
	echo "install ..."
	# https://github.com/YugaByte/yugabyte-db/releases
	install_package $NAME $DEST https://downloads.yugabyte.com/yugabyte-ce-1.0.4.0-darwin.tar.gz $SOURC
fi

# if [[ ! "$TESTS" ]]; then
# 	sudo yum install -y epel-release ntp
# fi

cd $DEST
./bin/post_install.sh

##################################################################################################
echo "clear data path ..."  
#exec_wrapper DISK rm -rf
exec_wrapper DISK mkdir -p

echo "configure ..."
echo -e "--master_addresses=$HOSTS \n--fs_data_dirs=$DISKS" > master.conf
echo -e "--tserver_master_addrs=$HOSTS \n--fs_data_dirs=$DISKS" > server.conf

echo -e "--rpc_bind_addresses=$LOCAL_HOST:$MASTER_PORT" >> master.conf
echo -e "--rpc_bind_addresses=$LOCAL_HOST:$SERVER_PORT" >> server.conf

##################################################################################################
echo "add tool path"
chmod +x $BASE_PATH/yugabyte/yuga
echo "PATH=\$PATH:$BASE_PATH/yugabyte" >> ~/.bashrc
