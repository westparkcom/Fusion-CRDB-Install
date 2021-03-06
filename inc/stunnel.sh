#!/bin/bash

if [ .$switch_tls = .'true' ]; then
	verbose "Switch TLS enabled, setting up stunnel4"
	apt install -y stunnel4
	cp ${switch_cert} /etc/ssl/certs/stunnel.crt
	cp ${switch_key} /etc/ssl/private/stunnel.key
	cp ${switch_chain} /etc/ssl/certs/stunnel-ca.crt
	echo "options = -NO_SSLv2" > /etc/stunnel/stunnel.conf
	echo "options = -NO_SSLv3" >> /etc/stunnel/stunnel.conf
	echo "options = -NO_TLSv1" >> /etc/stunnel/stunnel.conf
	echo "options = -NO_TLSv1.1" >> /etc/stunnel/stunnel.conf
	echo "cert = /etc/ssl/certs/stunnel.crt" >> /etc/stunnel/stunnel.conf
	echo "key = /etc/ssl/private/stunnel.key" >> /etc/stunnel/stunnel.conf
	echo "CAfile = /etc/ssl/certs/stunnel-ca.crt" >> /etc/stunnel/stunnel.conf
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
