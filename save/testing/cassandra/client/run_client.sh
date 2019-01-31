#!/bin/bash

:<<COMMENT
echo '
	export CLASSPATH=$CLASSPATH:/mnt/disk/client/lib::/mnt/disk/client
' >> ~/.bashrc
source ~/.bashrc
COMMENT

HOST=127.0.0.1

#####################################################################
java -jar client-*.jar -host $HOST $* 