#!/bin/bash

# 如果使用link指向的这个文本，那么$0就一直是link的路径
# if [ -L $0 ]; then
# 	curr=$(readlink -f $0)
# else
#     curr=$0
# fi

BASE_PATH=$(cd "$(dirname "$0")"; cd ..; pwd)
. $BASE_PATH/common/depend.sh

dyn_var() {
	echo `eval echo '$'${1}`
}

#	input:  loop_wrapper DISK
#	output: DISK1 DISK2
loop_wrapper() {
	NAME=$1

	INDEX=1
	while [ $(dyn_var $NAME$INDEX) ]; do
		# echo "$(dyn_var $NAME$INDEX)"
		echo "$(dyn_var $NAME$INDEX)"
		((INDEX=INDEX + 1))
	done
}

#	input:  comb_wrapper DISK
#	output: DISK1,DISK2
comb_wrapper() {
	NAME=$1

	first=1
	for i in $(loop_wrapper $NAME); do
		if (( $first == 1 )); then
			first=0
		else
			echo -n $2
		fi
		echo -n $i
	done
}

#	input:  comb_wrapper DISK
#	output: -- DISK1 -- DISK2
echo_wrapper() {
	NAME=$1
	shift

	prefix=$1
	suffix=$2
	for i in $(loop_wrapper $NAME); do
		echo -n $prefix $i $suffix
	done
}

#	input:  exec_wrapper DISK mkdir -p
#	output: mkdir -p DISK1; mkdir -p DISK2;
exec_wrapper() {
	NAME=$1
	shift
	
	for i in $(loop_wrapper $NAME); do
		echo "exec: $* $i"
		$* $i
	done
}

exec_wrapper_param() {
	NAME=$1
	prefix=$2
	suffix=$3
	shift
	shift
	shift
	
	for i in $(loop_wrapper $NAME); do
		combine=$prefix$i$suffix
		if [[ $combine == "" ]] || [[ $combine == "/" ]]; then
			echo "param error"
			exit 1
		fi
		echo "exec: $* $combine"
		$* $combine
	done
}

##################################################################################################
# install_package name dest local_path, url
install_package() {
	local NAME=$1
	local DEST=$2
	local URLS=$3
	local LOCAL=$4
	BASE=$(dirname $DEST)
	DOWN=/tmp/download

	# 文件在当前路径存在
	if ls $DOWN/*$NAME* >/dev/null 2>&1; then
		echo "already download package"
		SOURCE=$DOWN

	# 文件在local路径中存在
	elif [ -f $LOCAL/*$NAME* ]; then
		echo "package in local source"
		SOURCE=$LOCAL
	else
		echo "download package"
		mkdir -p $DOWN
		wget $URLS -P $DOWN
		SOURCE=$DOWN
	fi

	rm $DEST -rf
	tar zxvf $SOURCE/*$NAME* -C $BASE
	[[ $BASE ]] && mv $BASE/*$NAME* $DEST
}

tool_link() {
	if [[ $2 != "" ]]; then
		local NAME=$2
	else
		local NAME=tool
	fi
	local DEST=/usr/bin/$NAME

	# 检查一下避免误删除
	if [ -L $DEST ] || (( $(cat $DEST | wc -l) <= 3 )); then
		rm -f $DEST
	fi
	
	if [ ! -e $DEST ]; then
		# ln -s $1 $DEST
		echo ". $1 \$*" > $DEST
		chmod +x $DEST

		echo "link $DEST to $1"
	else
		echo "$DEST already exist, can't exec tool link"
	fi
}

show_help() {
	grep -E '^[[:space:]]*([[:alnum:]_]+[[:space:]]*\(\)|function[[:space:]]+[[:alnum:]_]+)' $1
}