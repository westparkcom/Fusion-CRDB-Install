#!/bin/bash

verbose "Installing nginx web server"

cp ./nginx/fusionpbx /etc/nginx/sites-available/fusionpbx
sed -i /etc/nginx/sites-available/fusionpbx -e "s#unix:.*;#unix:/var/run/php/php${php_ver}-fpm.sock;#g"

#self signed certificate
snakeoil_cert=/etc/ssl/certs/ssl-cert-snakeoil.pem
snakeoil_key=/etc/ssl/private/ssl-cert-snakeoil.key
nginx_cert=/etc/ssl/certs/nginx.crt
nginx_key=/etc/ssl/private/nginx.key

if [ .${www_cert} != ."" ]; then

	cat ${www_cert} ${www_chain} > ${nginx_cert}
	err_check $?
	cp ${www_key} ${nginx_key}
	err_check $?
	chmod 0600 ${nginx_key}
else
	make-ssl-cert generate-default-snakeoil --force-overwrite
	ln -s ${snakeoil_key} ${nginx_key}
	ln -s ${snakeoil_cert} ${nginx_cert}
fi

ln -s /etc/nginx/sites-available/fusionpbx /etc/nginx/sites-enabled/fusionpbx

#remove the default site
rm /etc/nginx/sites-enabled/default

#flush systemd cache
systemctl daemon-reload

#restart nginx
systemctl restart nginx
err_check $?
