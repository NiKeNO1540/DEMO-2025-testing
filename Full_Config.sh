#! /bin/bash

echo "Настройка ISP"

mkdir /etc/net/ifaces/ens21
mkdir /etc/net/ifaces/ens22
echo -e "BOOTPROTO=static\nTYPE=eth\nDISABLED=no\nCONFIG_IPV4=yes" > /etc/net/ifaces/ens21/options
echo -e "BOOTPROTO=static\nTYPE=eth\nDISABLED=no\nCONFIG_IPV4=yes" > /etc/net/ifaces/ens22/options
echo 172.16.1.1/28 > /etc/net/ifaces/ens21/ipv4address
echo 172.16.2.1/28 > /etc/net/ifaces/ens22/ipv4address
systemctl restart network

echo "Настройка IPTABLES"

apt-get install iptables -y
iptables -t nat -A POSTROUTING -o ens20 -s 172.16.1.0/28 -j MASQUERADE
iptables -t nat -A POSTROUTING -o ens20 -s 172.16.2.0/28 -j MASQUERADE
iptables-save > /etc/sysconfig/iptables
systemctl enable –-now iptables

echo "Раздача ключей"

ssh-keygen -t rsa -b 4096 -N "" -f ~/.ssh/id_rsa -q
ssh-keyscan -H 172.16.1.4 >> ~/.ssh/known_hosts
apt-get install sshpass -y
sshpass -p 'admin' ssh-copy-id admin@172.16.1.4
ssh-keyscan -H 172.16.2.5 >> ~/.ssh/known_hosts
sshpass -p 'admin' ssh-copy-id admin@172.16.2.5

echo "Настройка HQ-RTR|BR-RTR-Коммутация(Если по простому, базируется на инструментарии expect, очень зависимый на переменных)"

cd DEMO-2025-testing
apt-get update
apt-get install expect -y
systemctl enable --now sshd
expect hq-rtr-module-1.exp
expect br-rtr-module-1.exp

echo "Окончательная раздача ключей"

ssh-keyscan -p 2026 172.16.1.4 >> ~/.ssh/known_hosts
ssh-keyscan -p 2026 172.16.2.5 >> ~/.ssh/known_hosts
ssh-keyscan -p 2222 172.16.1.4 >> ~/.ssh/known_hosts
sshpass -p 'toor' ssh-copy-id -p 2026 root@172.16.2.5
sshpass -p 'toor' ssh-copy-id -p 2026 root@172.16.1.4
sshpass -p 'toor' ssh-copy-id -p 2222 root@172.16.1.4

echo "Смена название машины"

echo "hostnamectl set-hostname hq-srv.au-team.irpo; exec bash" | ssh -p 2026 root@172.16.1.4
echo "hostnamectl set-hostname hq-cli.au-team.irpo; exec bash" | ssh -p 2222 root@172.16.1.4
echo "hostnamectl set-hostname br-srv.au-team.irpo; exec bash" | ssh -p 2026 root@172.16.2.5

echo "Настройка DNS"

ssh -p 2026 root@172.16.1.4 "bash -s" < HQ-SRV-Launch.sh
echo "Настройка Samba"
ssh -p 2026 root@172.16.2.5 "bash -s" < samba-part-1.sh

cat << EOF | ssh -p 2222 root@172.16.1.4
echo nameserver 8.8.8.8 >> /etc/resolv.conf && apt-get update && apt-get install bind-utils -y
system-auth write ad AU-TEAM.IRPO cli AU-TEAM 'administrator' 'P@ssw0rd'
EOF
echo "reboot" | ssh -p 2222 root@172.16.1.4

ssh -p 2026 root@172.16.2.5 "bash -s" < samba-part-2.sh

sleep 15

sshpass -p 'toor' ssh-copy-id -p 2222 hquser1@172.16.1.4
cat << EOF | ssh -p 2222 hquser1@172.16.1.4
sudo cat /etc/passwd | sudo grep root && sudo id root
EOF


hostnamectl set-hostname ISP; exec bash
