#!/bin/bash

wget -O - https://files.freeswitch.org/repo/deb/debian-release/fsstretch-archive-keyring.asc | apt-key add -
echo "deb http://files.freeswitch.org/repo/deb/debian-release/ `lsb_release -sc` main" > /etc/apt/sources.list.d/freeswitch.list
echo "deb-src http://files.freeswitch.org/repo/deb/debian-release/ `lsb_release -sc` main" >> /etc/apt/sources.list.d/freeswitch.list

apt install -y gdb freeswitch-meta-bare freeswitch-conf-vanilla freeswitch-mod-commands freeswitch-mod-console freeswitch-mod-logfile freeswitch-lang-en freeswitch-mod-say-en freeswitch-sounds-en-us-callie freeswitch-mod-enum freeswitch-mod-cdr-csv freeswitch-mod-event-socket freeswitch-mod-sofia freeswitch-mod-sofia-dbg freeswitch-mod-loopback freeswitch-mod-conference freeswitch-mod-db freeswitch-mod-dptools freeswitch-mod-expr freeswitch-mod-fifo freeswitch-mod-httapi freeswitch-mod-hash freeswitch-mod-esl freeswitch-mod-esf freeswitch-mod-fsv freeswitch-mod-valet-parking freeswitch-mod-dialplan-xml freeswitch-dbg freeswitch-mod-sndfile freeswitch-mod-native-file freeswitch-mod-local-stream freeswitch-mod-tone-stream freeswitch-mod-lua freeswitch-meta-mod-say freeswitch-mod-xml-cdr freeswitch-mod-verto freeswitch-mod-callcenter freeswitch-mod-rtc freeswitch-mod-png freeswitch-mod-json-cdr freeswitch-mod-shout freeswitch-mod-sms freeswitch-mod-sms-dbg freeswitch-mod-cidlookup freeswitch-mod-memcache freeswitch-mod-imagick freeswitch-mod-tts-commandline freeswitch-mod-directory freeswitch-mod-flite freeswitch-mod-distributor freeswitch-meta-codecs freeswitch-mod-pgsql libyuv-dev
err_check $?

if [ .$servernum = .'1' ]; then
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