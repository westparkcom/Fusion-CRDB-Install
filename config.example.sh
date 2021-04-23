#!/bin/bash
baseconfig=present

# FusionPBX settings
## 'Primary' server, used for getting various configuration settings
prim_server=10.10.10.10

## Settings if this is a first time installation
### One of: hostname, ip_address or a custom value
domain_name=ip_address
system_username=admin
system_password=random
system_branch=master

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