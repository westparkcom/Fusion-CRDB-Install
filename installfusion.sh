#!/bin/sh

installtype = 'fusion'
# Color displays
. ./inc/colors.sh

if [ -d "/var/www/fusionpbx" ]; then
	error "FusionPBX already installed, exiting..."
	exit 1
fi
# import functions and do preflight checks
. ./inc/enviro.sh
. ./config.sh

if [ .$baseconfig != ."present" ]
	error "You must create config.sh from example file before installing!"
	exit 100
fi

# Ensure root user is installing
if [ .$EUID != .'0' ]; then
	error "You must be root to install, exiting..."
	exit 100
fi

echo "Is this the first server or an additional server? Enter 1 for first, 2 for additional"
read servernum

if [ .$servernum = .'1' ]; then
	echo "First server selected. This will initialize the database and create a fresh installation of FusionPBX. Continue (Y/N)?"
	read contq
	if [ .$contq = .'Y' ] || [ .$contq = .'y' ]; then 
		verbose "Continuing with installation"
	else
		warning "Installation cancelled!"
		exit 0
	fi
elif [ .$servernum = .'2' ]; then
	
else
	error "Bad entry, please select 1 or 2."
	exit 3
fi

# removes the cd img from the /etc/apt/sources.list file (not needed after base install)
sed -i '/cdrom:/d' /etc/apt/sources.list

# Update the system prior to installation
apt update
apt dist-upgrade

# Install base dependencies
apt install -y wget systemd systemd-sysv ca-certificates dialog nano net-tools snmpd

# SNMP Config
echo "rocommunity public" > /etc/snmp/snmpd.conf
systemctl restart snmpd

