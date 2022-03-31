#!/bin/bash
#Ensure lsb release is installed
err_check () {
	case $1 in
		0) ;;
		*) error "Program exiting abnormally with error code $1"; exit $1;
	esac
}

err_check_pass () {
	case $1 in
		0) ;;
		*) warning "$2";
	esac
}

apt update
apt install lsb-release

#operating system details
os_name=$(lsb_release -is)
os_codename=$(lsb_release -cs)

#cpu details
cpu_name=$(uname -m)

# Set program version
php_ver=None
php_lib=None

if [ .$cpu_name = .'x86_64' ]; then
	verbose "64 bit CPU detected!"
	if [ .$(grep -o -w 'lm' /proc/cpuinfo | head -n 1) = .'lm' ]; then
		verbose "64 bit OS detected!"
	else
		error "32 bit OS detected. Please install 64 bit OS!"
		exit 3
	fi
else
	error "32 bit CPU detected, please upgrade to hardware that supports 64 bit instructions!"
	exit 3
fi

if [ .$installtype = .'fusion' ]; then
	# Installing FusionPBX, only Debian 10 supported
	if [ .$os_name = .'Debian' ]; then
		if [ .$os_codename = .'buster' ]; then
			verbose "${os_name} ${os_codename} detected, continuing!"
			php_ver=7.3
			python_ver=3.7
			lua_ver=5.3
			php_lib=20180731
		elif [ .$os_codename = .'bullseye' ]; then
			verbose "${os_name} ${os_codename} detected, continuing!"
			php_ver=7.4
			python_ver=3.9
			lua_ver=5.4
			php_lib=20180731
		else
			error "${os_name} ${os_codename} detected, please use Debian buster or bullseye x86_64!"
			exit 3
		fi
	else
		error "${os_name} ${os_codename} detected, please use Debian buster x86_64!"
		exit 3
	fi
else
	#Installing Cockroach DB, Debian or Ubuntu is usable
	if [ .$os_name = .'Debian' ]; then
		if [ .$os_codename = .'buster' ] || [ .$os_codename = .'bullseye' ]; then
			verbose "${os_name} ${os_codename} detected, continuing!"
		else
			error "${os_name} ${os_codename} detected, please use Debian buster/bullseye x86_64 or Ubuntu focal x86_64!"
			exit 3
		fi
	elif [ .$os_name = .'Ubuntu' ]; then
		if [ .$os_codename = .'focal' ]; then
			verbose "${os_name} ${os_codename} detected, continuing!"
		else
			error "${os_name} ${os_codename} detected, please use Debian buster x86_64 or Ubuntu focal x86_64!"
			exit 3
		fi
	else
		error "${os_name} ${os_codename} detected, please use Debian buster x86_64 or Ubuntu focal x86_64!"
		exit 3
	fi
fi
