#!/bin/bash

installtype='fusion'
# Color displays
. ./inc/colors.sh

if [ -d "/var/www/fusionpbx" ]; then
	error "FusionPBX already installed, exiting..."
	exit 1
fi
# import functions and do preflight checks
. ./inc/enviro.sh
. ./config.sh

if [ .$baseconfig != ."present" ]; then
	error "You must create config.sh from config.example.sh file before installing!"
	exit 100
fi

# Ensure root user is installing
if [ .$EUID != .'0' ]; then
	error "You must be root to install, exiting..."
	exit 100
fi

echo "Is this the first server or an additional server? Enter 1 for first, 2 for additional"
read servernum
dbpass=None
if [ .$servernum = .'1' ]; then
	dbpass=$(dd if=/dev/urandom bs=1 count=20 2>/dev/null | base64)
	echo "First server selected. This will initialize the database and create a fresh installation of FusionPBX. Continue (Y/N)?"
	read contq
	if [ .$contq = .'Y' ] || [ .$contq = .'y' ]; then 
		verbose "Continuing with installation"
	else
		warning "Installation cancelled!"
		exit 0
	fi
elif [ .$servernum = .'2' ]; then
	verbose "Additional server selected"
else
	error "Bad entry, please select 1 or 2."
	exit 3
fi

# removes the cd img from the /etc/apt/sources.list file (not needed after base install)
sed -i '/cdrom:/d' /etc/apt/sources.list

# Enable backports
if [ .$os_codename = .'buster' ]; then
	echo deb http://deb.debian.org/debian buster-backports main > /etc/apt/sources.list.d/backports.list
fi

# Update the system prior to installation
apt update
apt dist-upgrade

# Install base dependencies
apt install -y wget systemd systemd-sysv ca-certificates dialog nano net-tools snmpd python3 python3-pip python python-pip sngrep vim git dbus haveged ssl-cert qrencode ghostscript libtiff5-dev libtiff-tools at zip unzip ffmpeg lua5.2 liblua5.2-dev luarocks libpq-dev cifs-utils curl gnupg2 nginx php${php_ver} php${php_ver}-cli php${php_ver}-fpm php${php_ver}-pgsql php${php_ver}-sqlite3 php${php_ver}-odbc php${php_ver}-curl php${php_ver}-imap php${php_ver}-xml php${php_ver}-gd memcached haveged apt-transport-https lsb-release postgresql-client gnupg2
err_check $?
if [ .$os_codename = .'buster' ]; then
	apt install -y haproxy=2.2.\* -t ${os_codename}-backports
else
	apt install -y haproxy=2.2.\*
fi
err_check $?
pip3 install boto3
err_check $?
pip3 install arrow
err_check $?
pip3 install PyMySQL
err_check $?
pip3 install ffmpy
err_check $?
pip3 install scp
err_check $?
pip3 install sshtunnel
err_check $?
pip3 install certifi gevent psycopg2 tenacity ws4py
err_check $?
luarocks install luasql-postgres PGSQL_INCDIR=/usr/include/postgresql
err_check $?

# SNMP Config
echo "rocommunity public" > /etc/snmp/snmpd.conf
systemctl restart snmpd

# Set up basic NTP
verbose "Setting up NTP"
cat > /etc/systemd/timesyncd.conf <<- EOM
[Time]
NTP=$fusion_ntp_servers
EOM
systemctl enable systemd-timesyncd
# NOTE: This won't work if you're using a container, you will need to set up NTP on the main host
systemctl start systemd-timesyncd
err_check_pass $? "Unable to start NTP sync. If you're running in a container this is expected, you will need to set up NTP on the host server"

# Set up Firewall
. ./inc/iptables.sh

# Set up PHP
. ./inc/php.sh

# Install FusionPBX
. ./inc/fusionpbx.sh

# Setup nginx
. ./inc/nginx.sh

# Install FreeSWITCH
. ./inc/freeswitch.sh

# Set up stunnel4
. ./inc/stunnel.sh

# Install Fail2ban
. ./inc/fail2ban.sh

# Database Setup
. ./inc/dbsetup.sh

# Install Syncthing
. ./inc/syncthing.sh

if [ .$servernum = .'1' ]; then
	if [ .${aws_access_key} != ."" ]; then
		cat < /usr/local/lib/python${python_ver}/dist-packages/fsglobs.py <<-EOM
class G:
	aws_access_key = '${aws_access_key}'
	aws_secret_key = '${aws_secret_key}'
	aws_region_name = '${aws_region_name}'
	tts_location = '/var/lib/freeswitch/storage/tts'
	tts_default_voice = '${aws_default_voice}'
	tmp_location = '/tmp'
EOM
	fi
else
	scp root@${fusion_host[0]}:/usr/local/lib/python${python_ver}/dist-packages/fsglobs.py /usr/local/lib/python${python_ver}/dist-packages/fsglobs.py
fi
cp /var/www/fusionpbx/resources/install/python/streamtext.py /usr/local/lib/python${python_ver}/dist-packages
cp -r /var/www/fusionpbx/resources/install/python/polly /usr/local/lib/python${python_ver}/dist-packages

echo ""
echo ""
verbose "Installation has completed."
if [ .$servernum = .'1' ]; then
	echo ""
	echo "   Use a web browser to login."
	echo "      domain name: https://$domain_name"
	echo "      username: $user_name"
	echo "      password: $user_password"
	echo ""
	echo "   The domain name in the browser is used by default as part of the authentication."
	echo "   If you need to login to a different domain then use username@domain."
	echo "      username: $user_name@$domain_name";
	echo ""
	warning "PLEASE REBOOT THIS SERVER FOR INSTALLATION TO FULLY COMPLETE!"
else
	echo ""
	warning "AFTER FILE SYNC COMPLETE, PLEASE REBOOT THIS SERVER FOR INSTALLATION TO FULLY COMPLETE!"
fi
