#!/bin/bash

verbose "Installing FusionPBX"

#add the cache directory
mkdir -p /var/cache/fusionpbx
chown -R www-data:www-data /var/cache/fusionpbx

#get the source code
git clone https://github.com/westparkcom/fusionpbx-wpc.git /var/www/fusionpbx
chown -R www-data:www-data /var/www/fusionpbx

if [ -v ${aws_access_key} ]; then
	cat /usr/local/lib/python2.7/dist-packages/fsglobs.py <<-EOM
class G:
	aws_access_key = '${aws_access_key}'
	aws_secret_key = '${aws_secret_key}'
	aws_region_name = '${aws_region_name}'
	tts_location = '/var/lib/freeswitch/storage/tts'
	tts_default_voice = '${aws_default_voice}'
	tmp_location = '/tmp'
EOM
	cp /var/www/fusionpbx/resources/install/python/streamtext.py /usr/local/lib/python2.7/dist-packages
	cp -r /var/www/fusionpbx/resources/install/python/polly /usr/local/lib/python2.7/dist-packages
fi
