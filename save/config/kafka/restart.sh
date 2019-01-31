killall -9 java
rm /tmp/kafka* -rf
rm /tmp/zookeeper/ -rf

bin/zookeeper-server-start.sh config/zookeeper.properties &
JMX_PORT=19797 bin/kafka-server-start.sh config/server.properties &

