#! /bin/bash


sudo_provider = ad' /etc/sssd/sssd.conf
sed -i 's/services = nss, pam,/services = nss, pam, sudo' /etc/sssd/sssd.conf
sed -i '28 a\
sudoers: files sss' /etc/nsswitch.conf

reboot
