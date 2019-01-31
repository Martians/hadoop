
# https://www.scylladb.com/download/centos_rpm/

## 配置
:<<COMMENT
echo "
export HOST1=100.1.1.10
export HOST2=100.1.1.11
export HOST3=100.1.1.12
export LOCAL=1" >> ~/.bashrc 
COMMENT

if [ ! $LOCAL ] || [ ! $HOST1 ] || [ ! $HOST2 ] || [ ! $HOST3 ]; then
	echo "should config: HOST1 HOST2 HOST3; LOCAL=1"
	echo "HOST1: $HOST1"
	echo "HOST2: $HOST2"
	echo "HOST3: $HOST3"
	echo "LOCAL: $LOCAL"
	exit -1
fi

dyn_var() {
	echo `eval echo '$'${1}`
}

##################################################################################################
CONFIG_FILE=/etc/scylla/scylla.yaml
CLUSTER=test_cluster
SEEDS=$HOST1,$HOST2
LOCAL=$(dyn_var HOST$LOCAL)
LISTEN=$LOCAL
RPC=$LOCAL

##################################################################################################
if yum list installed 2> /dev/null | grep -q scylla; then
	echo "already installed ..."
else
	echo "install ..."
	# 注意，yum不能使用代理
	# sed -i "s/\(proxy\)/#\1/g" /etc/yum.conf

	sudo yum remove -y abrt
	sudo yum install epel-release -y

	sudo curl -o /etc/yum.repos.d/scylla.repo -L http://repositories.scylladb.com/scylla/repo/db6bb488bae81d392ae3310b2e4ff105/centos/scylladb-2.1.repo
	sudo yum install scylla -y
fi

##################################################################################################
echo "configure ..."

sed -i "s/.*\(cluster_name: \).*/\1'$CLUSTER'/" $CONFIG_FILE
sed -i "s/\(- seeds: \).*/\1\"$SEEDS\"/" $CONFIG_FILE
sed -i "s/.*\(listen_address: \).*/\1\"$LISTEN\"/" $CONFIG_FILE
sed -i "s/.*\(rpc_address: \).*/\1\"$RPC\"/" $CONFIG_FILE
sed -i "s/.*\(experimental: \).*/\1true/" $CONFIG_FILE

cat $CONFIG_FILE | grep --color -e "cluster_name:" -e "- seeds:" -e "listen_address: " -e "rpc_address: " -e "experimental: "


##################################################################################################
echo "preparing ... "
umount /var/lib/scylla
mdadm -S /dev/md0
sudo scylla_setup
sudo systemctl start scylla-server

echo "check"
df -h | grep scylla

