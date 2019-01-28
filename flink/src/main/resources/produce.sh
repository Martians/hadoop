#!/bin/bash

target=$1

echo > ${target}
for ((i=0;i<30;i++))
do
  v=$(echo "scale=2; `date +%s` * 1.0 / `date +%N`" | bc)
  #echo "{\"gateway_id\":111,\"device_id\":\"testing\",\"real_data\":$v, \"timestampe\": `date +%s` }"
  echo "{\"gateway_id\":111,\"device_id\":\"testing\",\"real_data\":$v, \"timestamp\": `date +%s` }" >> ${target}
  sleep 1
done

# sh produces.sh bb
# bin/kafka-console-producer.sh --broker-list 192.168.0.81:9092 --topic test < bb
