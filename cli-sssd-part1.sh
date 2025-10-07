#! /bin/bash

useradd remote_user -u 2026
echo -e "P@ssw0rd\nP@ssw0rd" | passwd remote_user

apt-get install sudo libsss_sudo -y
control sudo public
sed -i '19 a\
sudo_provider = ad' /etc/sssd/sssd.conf
sed -i 's/services = nss, pam/services = nss, pam, sudo/' /etc/sssd/sssd.conf
sed -i '28 a\
sudoers: files sss' /etc/nsswitch.conf

hostnamectl set-hostname hq-cli.au-team.irpo

reboot
