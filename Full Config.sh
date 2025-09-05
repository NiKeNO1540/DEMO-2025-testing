#! /bin/bash

# Настройка ISP

mkdir /etc/net/ifaces/ens21
mkdir /etc/net/ifaces/ens22
echo -e "BOOTPROTO=static\nTYPE=eth\nDISABLED=no\nCONFIG_IPV4=yes" > /etc/net/ifaces/ens21/options
echo -e "BOOTPROTO=static\nTYPE=eth\nDISABLED=no\nCONFIG_IPV4=yes" > /etc/net/ifaces/ens21/options
sed -i "s/net.ipv4.ip_forward = 0/net.ipv4.ip_forward = 1/" /etc/net/sysctl.conf
systemctl restart network

# Настройка HQ-RTR-Коммутация(Это очень мощный костыль, но рабочий, базируется на expect.)

apt-get update
apt-get install expect -y
apt-get install sshpass -y
systemctl enable --now sshd
expect hq-rtr.exp

