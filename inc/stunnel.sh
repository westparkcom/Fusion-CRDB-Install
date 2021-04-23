#!/bin/bash

if [ .$switch_tls = .'true' ]; then
	verbose "Switch TLS enabled, setting up stunnel4"
	apt install -y stunnel4
	echo "options = -NO_SSLv2" > /etc/stunnel/stunnel.conf
	echo "options = -NO_SSLv3" >> /etc/stunnel/stunnel.conf
	echo "options = -NO_TLSv1" >> /etc/stunnel/stunnel.conf
	echo "options = -NO_TLSv1.1" >> /etc/stunnel/stunnel.conf
	echo "cert = ${switch_cert}" >> /etc/stunnel/stunnel.conf
	echo "key = ${switch_key}" >> /etc/stunnel/stunnel.conf
	echo "CAfile = ${switch_chain}" >> /etc/stunnel/stunnel.conf
	echo "" >> /etc/stunnel/stunnel.conf
	echo "[esls]" >> /etc/stunnel/stunnel.conf
	echo "accept = 8041" >> /etc/stunnel/stunnel.conf
	echo "connect = 8021" >> /etc/stunnel/stunnel.conf
	systemctl enable stunnel4
	systemctl restart stunnel4
	err_check_pass $? "stunnel4 failed to start, please check certificates and configuration after setup is complete and try starting it again"
else
	verbose "Switch TLS not enabled, skipping stunnel4 setup"
fi