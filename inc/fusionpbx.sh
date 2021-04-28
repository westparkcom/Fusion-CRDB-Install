#!/bin/bash

verbose "Installing FusionPBX"

#add the cache directory
mkdir -p /var/cache/fusionpbx
chown -R www-data:www-data /var/cache/fusionpbx

if [ .$servernum = .'1' ]; then
#get the source code
	git clone https://github.com/westparkcom/fusionpbx-wpc.git /var/www/fusionpbx
	chown -R www-data:www-data /var/www/fusionpbx
else
	mkdir /var/www/fusionpbx
	chown -R www-data:www-data /var/www/fusionpbx
fi
