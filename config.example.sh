#!/bin/bash
baseconfig=present

# FusionPBX settings
## List of all planned FusionPBX servers
fusion_host[0]=10.10.10.60
fusion_host[1]=10.10.10.61
fusion_host[2]=10.10.10.60
fusion_host[3]=10.10.10.60
fusion_ntp_servers=10.10.10.5 10.10.10.6

# Webserver certificate override
#www_cert=/path/to/cert.crt
#www_chain=/path/to/chain.crt
#www_key=/path/to/key.key

# Enable TLS on FreeSWITCH
#switch_tls=false

# FreeSWITCH TLS certificate override
#switch_cert=/path/to/cert.crt
#switch_chain=/path/to/chain.crt
#switch_key=/path/to/key.key

## Settings if this is a first time installation
### One of: hostname, ip_address or a custom value
domain_name=hostname
system_username=admin
system_password=random

## Database connection information, if installing fresh.
### Please include all IP addresses the server will connect to
db_host[0]=10.10.10.50
db_host[1]=10.10.10.51
db_host[2]=10.10.10.52
db_port=26257
check_port=8080


# CRDB Settings
## Download URL, will need to be updated as time goes on
crdb_version=cockroach-v20.2.7.linux-amd64
crdb_url=https://binaries.cockroachdb.com/cockroach-v20.2.7.linux-amd64.tgz
crdb_locality=region=us-central,zone=bcs
## We need NTP servers for Cockroach to maintain synchronization
crdb_ntp_servers=10.10.10.5 10.10.10.6