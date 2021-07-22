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

#Add API event runner to cron
if [ .$servernum = .'1' ]; then
	verbose "First server, skipping event runner cron."
else
	verbose "Adding event runner to cron"
	echo -e "* * * * *\troot\tphp /var/www/fusionpbx/core/events/event_runner.php" >> /etc/crontab
fi
