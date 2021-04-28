#!/bin/bash

wget -O - https://files.freeswitch.org/repo/deb/debian-release/fsstretch-archive-keyring.asc | apt-key add -
echo "deb http://files.freeswitch.org/repo/deb/debian-release/ `lsb_release -sc` main" > /etc/apt/sources.list.d/freeswitch.list
echo "deb-src http://files.freeswitch.org/repo/deb/debian-release/ `lsb_release -sc` main" >> /etc/apt/sources.list.d/freeswitch.list

apt update
apt install -y gdb freeswitch-meta-bare freeswitch-conf-vanilla freeswitch-mod-commands freeswitch-mod-console freeswitch-mod-logfile freeswitch-lang-en freeswitch-mod-python freeswitch-mod-say-en freeswitch-sounds-en-us-callie freeswitch-mod-enum freeswitch-mod-cdr-csv freeswitch-mod-event-socket freeswitch-mod-sofia freeswitch-mod-sofia-dbg freeswitch-mod-loopback freeswitch-mod-conference freeswitch-mod-db freeswitch-mod-dptools freeswitch-mod-expr freeswitch-mod-fifo freeswitch-mod-httapi freeswitch-mod-hash freeswitch-mod-esl freeswitch-mod-esf freeswitch-mod-fsv freeswitch-mod-valet-parking freeswitch-mod-dialplan-xml freeswitch-dbg freeswitch-mod-sndfile freeswitch-mod-native-file freeswitch-mod-local-stream freeswitch-mod-tone-stream freeswitch-mod-lua freeswitch-meta-mod-say freeswitch-mod-xml-cdr freeswitch-mod-verto freeswitch-mod-callcenter freeswitch-mod-rtc freeswitch-mod-png freeswitch-mod-json-cdr freeswitch-mod-shout freeswitch-mod-sms freeswitch-mod-sms-dbg freeswitch-mod-cidlookup freeswitch-mod-memcache freeswitch-mod-imagick freeswitch-mod-tts-commandline freeswitch-mod-directory freeswitch-mod-flite freeswitch-mod-distributor freeswitch-meta-codecs freeswitch-mod-pgsql
err_check $?

systemctl stop freeswitch
apt remove -y freeswitch-systemd

if [ .$servernum = .'1' ]; then
	# Enable mod_python
	sed -i /etc/freeswitch/autoload_configs/modules.conf.xml -e s:'<\!-- <load module="mod_python"/> -->:<load module="mod_python"/>:'
	# First server, initialize music on hold
	apt install -y freeswitch-music-default
	#remove the music package to protect music on hold from package updates
	mkdir -p /usr/share/freeswitch/sounds/temp
	mv /usr/share/freeswitch/sounds/music/*000 /usr/share/freeswitch/sounds/temp
	mv /usr/share/freeswitch/sounds/music/default/*000 /usr/share/freeswitch/sounds/temp
	apt-get remove -y freeswitch-music-default
	mkdir -p /usr/share/freeswitch/sounds/music/default
	mv /usr/share/freeswitch/sounds/temp/* /usr/share/freeswitch/sounds/music/default
	rm -R /usr/share/freeswitch/sounds/temp
fi


cat > /etc/defaults/freeswitch <<- EOM
# /etc/default/freeswitch
DAEMON_OPTS="-nonat"
EOM

cat > /lib/systemd/system/freeswitch.service <<- EOM
;;;;; Author: Travis Cross <tc@traviscross.com>

[Unit]
Description=freeswitch
Wants=network-online.target
Requires=network.target local-fs.target
After=network.target network-online.target local-fs.target

[Service]
; service
Type=forking
PIDFile=/run/freeswitch/freeswitch.pid
Environment="DAEMON_OPTS=-nonat"
Environment="USER=www-data"
Environment="GROUP=www-data"
EnvironmentFile=-/etc/default/freeswitch
ExecStartPre=/bin/mkdir -p /var/run/freeswitch
ExecStartPre=/bin/chown -R ${USER}:${GROUP} /var/lib/freeswitch /var/log/freeswitch /etc/freeswitch /var/run/freeswitch /usr/share/freeswitch/conf /usr/share/freeswitch/fonts /usr/share/freeswitch/grammar /usr/share/freeswitch/htdocs /usr/share/freeswitch/lang /usr/share/freeswitch/scripts /usr/share/freeswitch/tz
ExecStartPre=/bin/sleep 10
ExecStart=/usr/bin/freeswitch -u ${USER} -g ${GROUP} -ncwait ${DAEMON_OPTS}
TimeoutSec=45s
Restart=always
; exec
;User=${USER}
;Group=${GROUP}
LimitCORE=infinity
LimitNOFILE=100000
LimitNPROC=60000
LimitSTACK=250000
LimitRTPRIO=infinity
LimitRTTIME=infinity
IOSchedulingClass=realtime
IOSchedulingPriority=2
CPUSchedulingPolicy=rr
CPUSchedulingPriority=89
UMask=0007
NoNewPrivileges=false

; alternatives which you can enforce by placing a unit drop-in into
; /etc/systemd/system/freeswitch.service.d/*.conf:
;
; User=freeswitch
; Group=freeswitch
; ExecStart=
; ExecStart=/usr/bin/freeswitch -ncwait -nonat -rp
;
; empty ExecStart is required to flush the list.
;
; if your filesystem supports extended attributes, execute
;   setcap 'cap_net_bind_service,cap_sys_nice=+ep' /usr/bin/freeswitch
; this will also allow socket binding on low ports
;
; otherwise, remove the -rp option from ExecStart and
; add these lines to give real-time priority to the process:
;
; PermissionsStartOnly=true
; ExecStartPost=/bin/chrt -f -p 1 $MAINPID
;
; execute "systemctl daemon-reload" after editing the unit files.

[Install]
WantedBy=multi-user.target
EOM

chmod 644 /lib/systemd/system/freeswitch.service 
if [ -e /proc/user_beancounters ]
then
	#Disable CPU Scheduler for OpenVZ, not supported on OpenVZ."
	sed -i -e "s/CPUSchedulingPolicy=rr/;CPUSchedulingPolicy=rr/g" /lib/systemd/system/freeswitch.service
fi


if [ -v ${switch_tls} ]; then
	if [ .$servernum = .'1' ]; then
		verbose "Enabling TLS for FreeSWITCH"
		${switch_cert} ${switch_key} ${switch_chain} > /etc/freeswitch/tls/tls.pem
		${switch_cert} ${switch_key} ${switch_chain} > /etc/freeswitch/tls/wss.pem
		${switch_cert} ${switch_key} ${switch_chain} > /etc/freeswitch/tls/dtls-srtp.pem
		sed -i /etc/freeswitch/vars.xml -e 's#external_ssl_enable=false#external_ssl_enable=true#g'
		sed -i /etc/freeswitch/vars.xml -e 's#internal_ssl_enable=false#internal_ssl_enable=true#g'
fi

chown -R www-data:www-data /etc/freeswitch
chown -R www-data:www-data /var/lib/freeswitch
chown -R www-data:www-data /usr/share/freeswitch
chown -R www-data:www-data /var/log/freeswitch
chown -R www-data:www-data /var/run/freeswitch
chown -R www-data:www-data /var/cache/fusionpbx

systemctl enable freeswitch
systemctl unmask freeswitch.service
systemctl daemon-reload
