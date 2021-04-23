verbose "Installing Fail2ban"

#add the dependencies
apt install -y fail2ban

cp ./fail2ban/freeswitch.conf /etc/fail2ban/filter.d/freeswitch.conf
cp ./fail2ban/freeswitch-acl.conf /etc/fail2ban/filter.d/freeswitch-acl.conf
cp ./fail2ban/sip-auth-failure.conf /etc/fail2ban/filter.d/sip-auth-failure.conf
cp ./fail2ban/sip-auth-challenge.conf /etc/fail2ban/filter.d/sip-auth-challenge.conf
cp ./fail2ban/auth-challenge-ip.conf /etc/fail2ban/filter.d/auth-challenge-ip.conf
cp ./fail2ban/freeswitch-ip.conf /etc/fail2ban/filter.d/freeswitch-ip.conf
cp ./fail2ban/fusionpbx.conf /etc/fail2ban/filter.d/fusionpbx.conf
cp ./fail2ban/fusionpbx-mac.conf /etc/fail2ban/filter.d/fusionpbx-mac.conf
cp ./fail2ban/fusionpbx-404.conf /etc/fail2ban/filter.d/fusionpbx-404.conf
cp ./fail2ban/nginx-404.conf /etc/fail2ban/filter.d/nginx-404.conf
cp ./fail2ban/nginx-dos.conf /etc/fail2ban/filter.d/nginx-dos.conf
cp ./fail2ban/jail.local /etc/fail2ban/jail.local

systemctl restart fail2ban