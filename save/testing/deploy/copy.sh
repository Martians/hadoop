BASE_PATH=$(cd "$(dirname "$0")"; cd ..; pwd)
echo $BASE_PATH

scp -r $BASE_PATH 192.168.80.10:/root
scp -r $BASE_PATH 192.168.80.11:/root
scp -r $BASE_PATH 192.168.80.12:/root
