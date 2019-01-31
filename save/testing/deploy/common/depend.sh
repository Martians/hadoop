#!/bin/bash

install_java() {
	echo 11
}


install_yum() {
	echo 22	
}

install_depend() {
	check_exec=$1
	check_data=$2
	package=$3

	if $1 2>&1 | grep -q $2; then
		echo "already installed"
	else
		yum install $package -y
	fi
}