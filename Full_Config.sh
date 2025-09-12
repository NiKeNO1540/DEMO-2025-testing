#! /bin/bash

# Настройка ISP

mkdir /etc/net/ifaces/ens21
mkdir /etc/net/ifaces/ens22
echo -e "BOOTPROTO=static\nTYPE=eth\nDISABLED=no\nCONFIG_IPV4=yes" > /etc/net/ifaces/ens21/options
echo -e "BOOTPROTO=static\nTYPE=eth\nDISABLED=no\nCONFIG_IPV4=yes" > /etc/net/ifaces/ens22/options
echo 172.16.1.1/28 > /etc/net/ifaces/ens21/ipv4address
echo 172.16.2.1/28 > /etc/net/ifaces/ens22/ipv4address
systemctl restart network

# Настройка IPTABLES

apt-get install iptables -y
iptables -t nat -A POSTROUTING -o ens20 -s 172.16.1.0/28 -j MASQUERADE
iptables -t nat -A POSTROUTING -o ens20 -s 172.16.2.0/28 -j MASQUERADE
iptables-save > /etc/sysconfig/iptables
systemctl enable –-now iptables

# Раздача ключей

ssh-keygen -t rsa -b 4096 -N "" -f ~/.ssh/id_rsa -q
ssh-keyscan -H 172.16.1.4 >> ~/.ssh/known_hosts
apt-get install sshpass -y
sshpass -p 'admin' ssh-copy-id admin@172.16.1.4
ssh-keyscan -H 172.16.2.5 >> ~/.ssh/known_hosts
sshpass -p 'admin' ssh-copy-id admin@172.16.2.5

# Настройка HQ-RTR|BR-RTR-Коммутация(Если по простому, базируется на инструментарии expect, очень зависимый на переменных)

cd DEMO-2025-testing
apt-get update
apt-get install expect -y
systemctl enable --now sshd
expect hq-rtr-module-1.exp
expect br-rtr-module-1.exp


