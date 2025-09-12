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
ssh-keyscan -p 2026 172.16.1.4 >> ~/.ssh/known_hosts
ssh-keyscan -p 2026 172.16.2.5 >> ~/.ssh/known_hosts
sshpass -p 'toor' ssh-copy-id -p 2026 root@172.16.2.5
sshpass -p 'toor' ssh-copy-id -p 2026 root@172.16.1.4
sshpass -p 'toor' ssh-copy-id -p 2222 root@172.16.1.4

# Настройка HQ-RTR|BR-RTR-Коммутация(Если по простому, базируется на инструментарии expect, очень зависимый на переменных)

cd DEMO-2025-testing
apt-get update
apt-get install expect -y
systemctl enable --now sshd
expect hq-rtr-module-1.exp
expect br-rtr-module-1.exp

ssh -p 2026 root@172.16.1.4 "bash -s" < HQ-SRV-Launch.sh

ssh -p 2026 root@172.16.2.5 "bash -s" < samba-part-1.sh

cat << EOF | ssh -p 2222 root@172.16.1.4
echo nameserver 8.8.8.8 >> /etc/resolv.conf && apt-get update && apt-get install bind-utils -y
system-auth write ad AU-TEAM.IRPO cli AU-TEAM 'administrator' 'P@ssw0rd'
reboot
EOF

ssh -p 2026 root@172.16.2.5 "bash -s" < samba-part-2.sh

cat << EOF | ssh -p 2222 root@172.16.1.4
apt-get install sudo libsss_sudo -y
control sudo public

sed -i '19 a\
sudo_provider = ad' /etc/sssd/sssd.conf
sed -i 's/services = nss, pam,/services = nss, pam, sudo' /etc/sssd/sssd.conf
sed -i '28 a\
sudoers: files sss' /etc/nsswitch.conf

reboot
EOF

sleep 15

cat << EOF | ssh -p 2222 root@172.16.1.4
rm -rf /var/lib/sss/db/*
sss_cache -E
systemctl restart sssd

sudo -l -U hquser1
reboot
EOF

sleep 15

sshpass -p 'toor' ssh-copy-id -p 2222 hquser1@172.16.1.4
cat << EOF | ssh -p 2222 hquser1@172.16.1.4
sudo cat /etc/passwd | sudo grep root && sudo id root
EOF
