#! /bin/bash

# Настройка ISP

mkdir /etc/net/ifaces/ens21
mkdir /etc/net/ifaces/ens22
echo -e "BOOTPROTO=static\nTYPE=eth\nDISABLED=no\nCONFIG_IPV4=yes" > /etc/net/ifaces/ens21/options
echo -e "BOOTPROTO=static\nTYPE=eth\nDISABLED=no\nCONFIG_IPV4=yes" > /etc/net/ifaces/ens22/options
echo 172.16.4.1 > /etc/net/ifaces/ens21/ipv4address
echo 172.16.5.1 > /etc/net/ifaces/ens22/ipv4address
sed -i "s/net.ipv4.ip_forward = 0/net.ipv4.ip_forward = 1/" /etc/net/sysctl.conf
systemctl restart network

# Раздача ключей

ssh-keygen -t rsa -b 4096 -N "" -f ~/.ssh/id_rsa -q
ssh-keyscan -H 172.16.4.4 >> ~/.ssh/known_hosts
apt-get install sshpass -y
sshpass -p 'admin' ssh-copy-id admin@172.16.4.4
ssh-keyscan -H 172.16.5.5 >> ~/.ssh/known_hosts
sshpass -p 'admin' ssh-copy-id admin@172.16.5.5

# Настройка HQ-RTR-BR-RTR-Коммутация(Это очень мощный костыль, но рабочий, базируется на expect.)

cd DEMO-2025-testing
apt-get update
apt-get install expect -y
systemctl enable --now sshd
expect hq-rtr-module-1.exp
expect br-rtr-module-1.exp
