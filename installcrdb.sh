#!/bin/bassh

installtype='crdb'
# Color displays
. ./inc/colors.sh

# Ensure root user is installing
if [ .$EUID != .'0' ]; then
	error "You must be root to install, exiting..."
	exit 100
fi

if [ -f "/usr/local/cockroach/certs/safe/ca.crt" ]; then 
	error "CockroachDB already installed, exiting..."
	exit 1
fi
# import functions and do preflight checks
. ./inc/enviro.sh
. ./config.sh

if [ .$baseconfig != ."present" ]
	error "You must create config.sh from config.example.sh file before installing!"
	exit 100
fi

echo "Is this the first server or an additional server? Enter 1 for first, 2 for additional"
read servernum

if [ .$servernum = .'1' ]; then
	echo "First server selected. This will initialize create a fresh installation of CockroachDB. Continue (Y/N)?"
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

# Get list of IP addresses
read -ra iplist <<< `hostname -I`
crdb_hosts=$(printf ",%s" "${db_host[@]}")
crdb_hosts=${crdb_hosts:1}

# removes the cd img from the /etc/apt/sources.list file (not needed after base install)
sed -i '/cdrom:/d' /etc/apt/sources.list

# Update the system prior to installation
apt update
apt dist-upgrade

# Install base dependencies
apt install -y wget nano net-tools

# Download CRDB, install binary
verbose "Downloading and installing Cockroach."
wget -qO- $crdb_url | tar xvz
err_check $?
cp -i ${crdb_version}/cockroach /usr/local/bin

verbose "Adding cockroach user"
useradd cockroach
mkdir /usr/local/cockroach
mkdir /usr/local/cockroach/certs
mkdir /usr/local/cockroach/certs/safe
mkdir /var/local/cockroach
mkdir /var/local/cockroach/data
mkdir /var/log/cockroach

# Create CA certificate and root client if this is the first server in the cluster
if [ .$servernum = .'1' ]; then
	verbose "Creating CA certificate, please enter relevant information to create CA"
	cockroach cert create-ca --certs-dir=/usr/local/cockroach/certs --ca-key=/usr/local/cockroach/certs/safe/ca.key
	err_check $?
	verbose "Creating root client certificate"
	cockroach cert create-client root --certs-dir=/usr/local/cockroach/certs --ca-key=/usr/local/cockroach/certs/safe/ca.key
else
	verbose "Creating SSH key. PLEASE LEAVE THE PASSWORD BLANK"
	ssh-keygen -t rsa -b 4096 -C "${iplist[0]}" -f /root/.ssh/id_rsa
	err_check $?
	warning "You will need to copy the text in between the ------------ markers into the file /root/.ssh/authorized_keys on server ${db_host[0]}"
	echo
	warning "------------"
	cat /root/.ssh/id_rsa.pub
	warning "------------"
	echo "When you have added this text to the file /root/.ssh/authorized_keys on server ${db_host[0]}, press Enter to continue"
	read placeholder
	scp root@${db_host[0]}:/usr/local/cockroach/certs/safe/ca.key /usr/local/cockroach/certs/safe
	err_check $?
	scp root@${db_host[0]}:/usr/local/cockroach/certs/ca.crt /usr/local/cockroach/certs
	err_check $?
	scp root@${db_host[0]}:/usr/local/cockroach/certs/client.root.* /usr/local/cockroach/certs
	err_check $?
fi

hostsraw="`hostname` `hostname -f` `hostname -a` `hostname -i` `hostname -I` 127.0.0.1 localhost"
hosts=`echo $hostsraw | tr '[:upper:]' '[:lower:]'`

# Create our node certificate
verbose "Creating node certificate"
cockroach cert create-node $hosts --certs-dir=/usr/local/cockroach/certs --ca-key=/usr/local/cockroach/certs/safe/ca.key

chown -R cockroach:cockroach /usr/local/cockroach
chown -R cockroach:cockroach /var/log/cockroach
chmod 0700 /usr/local/cockroach/certs/safe

# Set up basic NTP
verbose "Setting up NTP"
cat > /etc/systemd/timesyncd.conf <<- EOM
[Time]
NTP=$crdb_ntp_servers
EOM

systemctl enable systemd-timesyncd
# NOTE: This won't work if you're using a container, you will need to set up NTP on the main host
systemctl start systemd-timesyncd
err_check_pass $? "Unable to start NTP sync. If you're running in a container this is expected, you will need to set up NTP on the host server"


# Create Cockroach systemd file
verbose "Creating CockroachDB systemd service file"
cat > /etc/systemd/system/cockroach.service <<- EOM
[Unit]
Description=Cockroach Database cluster node
Requires=network.target
[Service]
Type=notify
WorkingDirectory=/usr/local/cockroach
ExecStart=/usr/local/bin/cockroach start --locality=region=us-central,zone=bcs --certs-dir=/usr/local/cockroach/certs --advertise-addr=${iplist[0]} --join=${crdb_hosts} --cache=.25 --max-sql-memory=.25
TimeoutStopSec=60
Restart=always
RestartSec=10
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=cockroach
User=cockroach
[Install]
WantedBy=default.target
EOM

verbose "Starting CockroachDB"
systemctl enable cockroach
systemctl start cockroach
err_check $?

if [ .$servernum = .'1' ]; then
	verbose "Initializing CockroachDB server"
	cockroach init --certs-dir=/usr/local/cockroach/certs/ --host=${iplist[0]}
	err_check $?
	verbose "Initialization complete. Please add a new user for web UI login using the following commands, replacing <sql_user> and <sql_password> with a username and password of your choice:"
	warning "cockroach sql --certs-dir=/usr/local/cockroach/certs"
	warning "CREATE USER <sql_user> WITH LOGIN PASSWORD '<sql_password>';"
	warning "GRANT admin TO <sql_user>;"
	echo
	verbose "Once you have added the user you will be able to log into http://${iplist[0]:8080 with the credentials you added"
fi
echo
verbose "Installation complete!"