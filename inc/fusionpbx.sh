#!/bin/bash

verbose "Installing FusionPBX"

#add the cache directory
mkdir -p /var/cache/fusionpbx
chown -R www-data:www-data /var/cache/fusionpbx

#get the source code
git clone $branch https://github.com/westparkcom/fusionpbx-wpc.git /var/www/fusionpbx
chown -R www-data:www-data /var/www/fusionpbx