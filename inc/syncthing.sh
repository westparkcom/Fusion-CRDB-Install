#!/bin/bash

verbose "Installing syncthing"
curl -s -o /usr/share/keyrings/syncthing-archive-keyring.gpg https://syncthing.net/release-key.gpg
err_check $?
echo "deb [signed-by=/usr/share/keyrings/syncthing-archive-keyring.gpg] https://apt.syncthing.net/ syncthing stable" | tee /etc/apt/sources.list.d/syncthing.list
apt update
apt install syncthing
err_check $?

cat > /lib/systemd/system/syncthing.service <<-EOM
[Unit]
Description=Syncthing - Open Source Continuous File Synchronization
Documentation=man:syncthing(1)
After=network.target

[Service]
User=www-data
Type=simple
ExecStart=/usr/bin/syncthing serve --no-browser --no-restart --logflags=0
Restart=on-failure
RestartSec=1
StartLimitIntervalSec=60
StartLimitBurst=4
SuccessExitStatus=3 4
RestartForceExitStatus=3 4

# Hardening
#ProtectSystem=full
#PrivateTmp=true
#SystemCallArchitectures=native
#MemoryDenyWriteExecute=true
#NoNewPrivileges=true

[Install]
WantedBy=multi-user.target
EOM

systemctl daemon-reload
chown -R www-data:www-data /var/www
echo "fs.inotify.max_user_watches=204800" | tee -a /etc/sysctl.conf
echo 204800 > /proc/sys/fs/inotify/max_user_watches
systemctl start syncthing
err_check $?

python3 ./inc/syncsetup.py ${servernum} ${fusion_host[0]}
err_check $?
