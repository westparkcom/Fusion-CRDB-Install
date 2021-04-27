#!/bin/bash

php_ini_file="/etc/php/${php_ver}/fpm/php.ini"

sed 's#post_max_size = .*#post_max_size = 80M#g' -i $php_ini_file
sed 's#upload_max_filesize = .*#upload_max_filesize = 80M#g' -i $php_ini_file
sed 's#;max_input_vars = .*#max_input_vars = 8000#g' -i $php_ini_file
sed 's#; max_input_vars = .*#max_input_vars = 8000#g' -i $php_ini_file

if [ -d "ioncube" ]; then
	rm -Rf ioncube;
fi
verbose "Installing ioncube PHP library"
wget --no-check-certificate https://downloads.ioncube.com/loader_downloads/ioncube_loaders_lin_x86-64.zip
err_check $?
unzip ioncube_loaders_lin_x86-64.zip
rm ioncube_loaders_lin_x86-64.zip
cp ioncube/ioncube_loader_lin_${php_ver}.so /usr/lib/php/${php_lib}

systemctl restart php${php_ver}-fpm
