#!/bin/bash

exec_sql () {
	ssh root@${db_host[0]} 'cockroach sql --execute="$1" --certs-dir=/usr/local/cockroach/certs'
	err_check $?
}

verbose "Creating HAProxy configuration"
echo -e "global" > /etc/haproxy/haproxy.cfg
echo -e "\tlog /dev/log\tlocal0" >> /etc/haproxy/haproxy.cfg
echo -e "\tlog /dev/log\tlocal1 notice" >> /etc/haproxy/haproxy.cfg
echo -e "\tchroot /var/lib/haproxy" >> /etc/haproxy/haproxy.cfg
echo -e "\tuser haproxy" >> /etc/haproxy/haproxy.cfg
echo -e "\tgroup haproxy" >> /etc/haproxy/haproxy.cfg
echo -e "\tmaxconn 4096" >> /etc/haproxy/haproxy.cfg
echo -e "" >> /etc/haproxy/haproxy.cfg
echo -e "defaults" >> /etc/haproxy/haproxy.cfg
echo -e "\tmode tcp" >> /etc/haproxy/haproxy.cfg
echo -e "\ttimeout connect 10s" >> /etc/haproxy/haproxy.cfg
echo -e "\ttimeout client 10h" >> /etc/haproxy/haproxy.cfg
echo -e "\ttimeout server 10h" >> /etc/haproxy/haproxy.cfg
echo -e "\toption clitcpka" >> /etc/haproxy/haproxy.cfg
echo -e "" >> /etc/haproxy/haproxy.cfg
echo -e "listen stats" >> /etc/haproxy/haproxy.cfg
echo -e "\tbind :1936" >> /etc/haproxy/haproxy.cfg
echo -e "\tmode http" >> /etc/haproxy/haproxy.cfg
echo -e "\tlog global" >> /etc/haproxy/haproxy.cfg
echo -e "\tmaxconn 10" >> /etc/haproxy/haproxy.cfg
echo -e "\ttimeout client 100s" >> /etc/haproxy/haproxy.cfg
echo -e "\ttimeout server 100s" >> /etc/haproxy/haproxy.cfg
echo -e "\ttimeout connect 100s" >> /etc/haproxy/haproxy.cfg
echo -e "\ttimeout queue 100s" >> /etc/haproxy/haproxy.cfg
echo -e "\tstats enable" >> /etc/haproxy/haproxy.cfg
echo -e "\tstats hide-version" >> /etc/haproxy/haproxy.cfg
echo -e "\tstats refresh 30s" >> /etc/haproxy/haproxy.cfg
echo -e "\tstats show-node" >> /etc/haproxy/haproxy.cfg
echo -e "\tstats auth admin:${dbpass}" >> /etc/haproxy/haproxy.cfg
echo -e "\tstats uri /haproxy?stats" >> /etc/haproxy/haproxy.cfg
echo -e "" >> /etc/haproxy/haproxy.cfg
echo -e "listen psql" >> /etc/haproxy/haproxy.cfg
echo -e "\tbind :26257" >> /etc/haproxy/haproxy.cfg
echo -e "\tmode tcp" >> /etc/haproxy/haproxy.cfg
echo -e "\tbalance roundrobin" >> /etc/haproxy/haproxy.cfg
echo -e "\t#stick-table type integer size 10k" >> /etc/haproxy/haproxy.cfg
echo -e "\t#stick on src_port" >> /etc/haproxy/haproxy.cfg
echo -e "\toption httpchk GET /health?ready=1" >> /etc/haproxy/haproxy.cfg
j=1
for i in "${db_host[@]}"
do
	echo -e "\tserver cockroach${j} ${i}:${db_port} check port ${check_port} weight 10" >> /etc/haproxy/haproxy.cfg
	((j=j+1))
done
echo -e "" >> /etc/haproxy/haproxy.cfg

systemctl restart haproxy
err_check $?

mkdir -p /etc/fusionpbx
chown -R www-data:www-data /etc/fusionpbx

verbose "Creating SSH key. PLEASE LEAVE THE PASSWORD BLANK"
ssh-keygen -t rsa -b 4096 -C "${iplist[0]}" -f /root/.ssh/id_rsa
err_check $?

if [ .$servernum = .'1' ]; then
	warning "You will need to copy the text in between the ------------ markers into the file /root/.ssh/authorized_keys on server ${db_host[0]}"
	echo
	warning "------------"
	cat /root/.ssh/id_rsa.pub
	warning "------------"
	verbose "Adding database users"
	warning "If you asked if you want to continue connecting, enter yes and press enter"
	exec_sql "CREATE USER fusionpbx WITH LOGIN PASSWORD ${dbpass};"
	exec_sql "CREATE USER freeswitch WITH LOGIN PASSWORD ${dbpass};"
	exec_sql "CREATE DATABASE freeswitch;"
	exec_sql "CREATE DATABASE fusionpbx;"
	exec_sql "GRANT ALL PRIVILEGES ON DATABASE fusionpbx to fusionpbx;"
	exec_sql "GRANT ALL PRIVILEGES ON DATABASE freeswitch to fusionpbx;"
	exec_sql "GRANT ALL PRIVILEGES ON DATABASE freeswitch to freeswitch;"
	scp root@${db_host[0]}:/usr/local/cockroach/certs/ca.crt /etc/fusionpbx
	err_check $?
	cp ./fusionpbx/config.php /etc/fusionpbx
	err_check $?
	sed -i /etc/fusionpbx/config.php -e s:"{database_host}:127\.0\.0\.1:"
	sed -i /etc/fusionpbx/config.php -e s:'{database_username}:fusionpbx:'
	sed -i /etc/fusionpbx/config.php -e s:"{database_password}:$dbpass"
	sed -i /etc/fusionpbx/config.php -e s:"{database_port}:$db_port:"
	
	verbose "Initializing FusionPBX database"
	
	#get the server hostname
	if [ .$domain_name = .'hostname' ]; then
		domain_name=$(hostname -f)
	fi

	#get the ip address
	if [ .$domain_name = .'ip_address' ]; then
		domain_name=$(hostname -I | cut -d ' ' -f1)
	fi
	
else
	warning "You will need to copy the text in between the ------------ markers into the file /root/.ssh/authorized_keys on server ${fusion_host[0]}"
	echo
	warning "------------"
	cat /root/.ssh/id_rsa.pub
	warning "------------"
	echo "When you have added this text to the file /root/.ssh/authorized_keys on server ${fusion_host[0]}, press Enter to continue"
	read placeholder
fi


if [ .$servernum = .'1' ]; then
	
else

fi