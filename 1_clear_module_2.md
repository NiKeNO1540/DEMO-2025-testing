# Чистый код, используемый в скриптах, предполагается, что будет использоваться строго после полного выполнения 1-го модуля

## Содержание:
[Полная конфигурация](https://github.com/NiKeNO1540/DEMO-2025-testing/edit/main/1clear_module_2.md#%D0%BF%D0%BE%D0%BB%D0%BD%D0%B0%D1%8F-%D0%BA%D0%BE%D0%BD%D1%84%D0%B8%D0%B3%D1%83%D1%80%D0%B0%D1%86%D0%B8%D1%8F-%D0%B1%D0%B5%D0%B7-%D1%80%D0%B0%D0%B7%D0%B4%D0%B5%D0%BB%D0%B5%D0%BD%D0%B8%D1%8F-%D0%BD%D0%B0-%D0%BF%D1%83%D0%BD%D0%BA%D1%82%D1%8B-%D1%82%D0%B5%D0%BC-%D0%BA%D0%BE%D0%BC%D1%83-%D0%BD%D1%83%D0%B6%D0%B5%D0%BD-%D1%87%D0%B8%D1%81%D1%82%D1%8B%D0%B9-%D0%BA%D0%BE%D0%B4)

[Samba-DC](https://github.com/NiKeNO1540/DEMO-2025-testing/blob/main/1clear_module_2.md#samba-dc)

[Raid](https://github.com/NiKeNO1540/DEMO-2025-testing/blob/main/1clear_module_2.md#samba-dc)

[Chrony](https://github.com/NiKeNO1540/DEMO-2025-testing/blob/main/1clear_module_2.md#chrony)

[Ansible+Динамическая трансляция портов](https://github.com/NiKeNO1540/DEMO-2025-testing/blob/main/1clear_module_2.md#ansible--%D0%B4%D0%B8%D0%BD%D0%B0%D0%BC%D0%B8%D1%87%D0%B5%D1%81%D0%BA%D0%B0%D1%8F-%D1%82%D1%80%D0%B0%D0%BD%D1%81%D0%BB%D1%8F%D1%86%D0%B8%D1%8F-%D0%BF%D0%BE%D1%80%D1%82%D0%BE%D0%B2-%D0%B4%D0%B5%D0%BB%D0%B0%D0%B5%D1%82%D1%81%D1%8F-%D1%82%D0%BE%D0%BB%D1%8C%D0%BA%D0%BE-%D0%B4%D0%BB%D1%8F-%D1%82%D0%BE%D0%B3%D0%BE-%D1%87%D1%82%D0%BE%D0%B1%D1%8B-%D0%BC%D0%BE%D0%B6%D0%BD%D0%BE-%D0%B1%D1%8B%D0%BB%D0%BE-%D0%B0%D0%B2%D1%82%D0%BE%D0%BC%D0%B0%D1%82%D0%B8%D0%B7%D0%B8%D1%80%D0%BE%D0%B2%D0%B0%D1%82%D1%8C)

[Docker](https://github.com/NiKeNO1540/DEMO-2025-testing/blob/main/1clear_module_2.md#docker)

[Web-Server](https://github.com/NiKeNO1540/DEMO-2025-testing/blob/main/1clear_module_2.md#web-interface)

[Nginx+Web-auth](https://github.com/NiKeNO1540/DEMO-2025-testing/blob/main/1clear_module_2.md#nginx--web-auth)

---
<details>
<summary>Полная конфигурация (Без разделения на пункты, тем, кому нужен чистый код)</summary>

### HQ-RTR

```tcl
en
conf
ip nat source static tcp 192.168.1.10 80 172.16.1.4 8080
ip nat source static tcp 192.168.1.10 2026 172.16.1.4 2026
ip nat source static tcp 192.168.2.10 2222 172.16.1.4 2222
end
wr
```

### BR-RTR

```tcl
en
conf
ip nat source static tcp 192.168.3.10 8080 172.16.2.5 8080
ip nat source static tcp 192.168.3.10 2026 172.16.2.5 2026
end
wr
```

### ISP
```bash
apt-get install nginx -y
apt-get install apache2-htpasswd -y


htpasswd -bc /etc/nginx/.htpasswd WEB P@ssw0rd

mkdir -p /etc/nginx/sites-available.d
mkdir -p /etc/nginx/sites-enabled.d

cat << EOF > /etc/nginx/sites-available.d/proxy.conf
server {
    listen 80;
    server_name web.au-team.irpo;
    
    auth_basic "Restricted Access";
    auth_basic_user_file /etc/nginx/.htpasswd;
    
    location / {
        proxy_pass http://172.16.1.4:8080;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }
}

server {
    listen 80;
    server_name docker.au-team.irpo;
    
    location / {
        proxy_pass http://172.16.2.5:8080;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }
}
EOF


ln -sf /etc/nginx/sites-available.d/proxy.conf /etc/nginx/sites-enabled.d/

log_message "Проверка конфигурации nginx"
nginx -t

log_message "Включение и запуск nginx"
systemctl enable --now nginx
systemctl restart nginx
apt-get install chrony -y
cat << EOF > /etc/chrony.conf
server 127.0.0.1 iburst prefer
hwtimestamp *
local stratum 5
allow 0/0
EOF
systemctl enable --now chronyd
```

### HQ-SRV

```bash
echo "server=/br-srv.au-team.irpo/192.168.3.10" >> /etc/dnsmasq.conf
systemctl restart dnsmasq
mdadm --create /dev/md0 --level=0 --raid-devices=2 /dev/sd[b-c]
mdadm --detail -scan --verbose > /etc/mdadm.conf
apt-get update && apt-get install fdisk -y
fdisk /dev/md0 << EOF
n
p
1
2048
4186111
w
EOF

mkfs.ext4 /dev/md0p1
cat << EOF >> /etc/fstab
/dev/md0p1  /raid  ext4  defaults  0  0
EOF

mkdir /raid
mount -a

apt-get install nfs-server -y
mkdir /raid/nfs
chown 99:99 /raid/nfs
chmod 777 /raid/nfs

cat << EOF >> /etc/exports
/raid/nfs  192.168.2.0/28(rw,sync,no_subtree_check)
EOF
exportfs -a
exportfs -v
systemctl enable nfs
systemctl restart nfs

apt-get update
apt-get install apache2 php8.2 apache2-mod_php8.2 mariadb-server php8.2-{opcache,curl,gd,intl,mysqli,xml,xmlrpc,ldap,zip,soap,mbstring,json,xmlreader,fileinfo,sodium} -y

systemctl enable --now httpd2 mariadb

mkdir -p /mnt/additional
mount /dev/sr0 /mnt/additional -o ro

mkdir -p /tmp/web_setup
cp -r /mnt/additional/web/* /tmp/web_setup/

mysql -e "CREATE DATABASE webdb CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
mysql -e "CREATE USER 'webc'@'localhost' IDENTIFIED BY 'P@ssw0rd';"
mysql -e "GRANT ALL PRIVILEGES ON webdb.* TO 'webc'@'localhost';"
mysql -e "FLUSH PRIVILEGES;"

cd /tmp/web_setup

file -i dump.sql

if file -i dump.sql | grep -q "utf-16"; then
    iconv -f UTF-16 -t UTF-8 dump.sql > dump_utf8.sql
    mysql -u root webdb < dump_utf8.sql
else
    mysql -u root webdb < dump.sql
fi

cp index.php /var/www/html/
cp -r logo.png /var/www/html/

chown -R apache2:apache2 /var/www/html
chmod -R 755 /var/www/html

sed -i "s/\$servername = .*;/\$servername = 'localhost';/" /var/www/html/index.php
sed -i "s/\$dbname = .*;/\$dbname = 'webdb';/" /var/www/html/index.php
sed -i "s/\$password = .*;/\$password = 'P@ssw0rd';/" /var/www/html/index.php
sed -i "s/\$username = .*;/\$username = 'webc';/" /var/www/html/index.php

sed -i 's/\tDirectoryIndex index.html index.cgi index.pl index.php index.xhtml index.htm/\tDirectoryIndex index.php index.html index.cgi index.pl index.xhtml index.htm/' /etc/httpd2/conf/mods-enabled/dir.conf
rm -rf /var/www/html/index.html

systemctl restart httpd2

curl -I http://localhost/

apt-get install chrony -y
echo -e 'server 172.16.1.4 iburst prefer' > /etc/chrony.conf
systemctl enable --now chronyd
```

### BR-SRV

```bash
echo nameserver 8.8.8.8 >> /etc/resolv.conf && apt-get update && apt-get install wget dos2unix task-samba-dc -y
sleep 3
echo nameserver 192.168.1.10 >> /etc/resolv.conf
sleep 2
echo 192.168.3.10 br-srv.au-team.irpo >> /etc/hosts
rm -rf /etc/samba/smb.conf
samba-tool domain provision --realm=AU-TEAM.IRPO --domain=AU-TEAM --adminpass=P@ssw0rd --dns-backend=SAMBA_INTERNAL --server-role=dc --option='dns forwarder=192.168.1.10'
mv -f /var/lib/samba/private/krb5.conf /etc/krb5.conf
systemctl enable --now samba.service
samba-tool user add hquser1 P@ssw0rd
samba-tool user add hquser2 P@ssw0rd
samba-tool user add hquser3 P@ssw0rd
samba-tool user add hquser4 P@ssw0rd
samba-tool user add hquser5 P@ssw0rd
samba-tool group add hq
samba-tool group addmembers hq hquser1,hquser2,hquser3,hquser4,hquser5
wget https://raw.githubusercontent.com/sudo-project/sudo/main/docs/schema.ActiveDirectory
dos2unix schema.ActiveDirectory
sed -i 's/DC=X/DC=au-team,DC=irpo/g' schema.ActiveDirectory
head -$(grep -B1 -n '^dn:$' schema.ActiveDirectory | head -1 | grep -oP '\d+') schema.ActiveDirectory > first.ldif
tail +$(grep -B1 -n '^dn:$' schema.ActiveDirectory | head -1 | grep -oP '\d+') schema.ActiveDirectory | sed '/^-/d' > second.ldif
ldbadd -H /var/lib/samba/private/sam.ldb first.ldif --option="dsdb:schema update allowed"=true
ldbmodify -v -H /var/lib/samba/private/sam.ldb second.ldif --option="dsdb:schema update allowed"=true
samba-tool ou add 'ou=sudoers'
cat << EOF > sudoRole-object.ldif
dn: CN=prava_hq,OU=sudoers,DC=au-team,DC=irpo
changetype: add
objectClass: top
objectClass: sudoRole
cn: prava_hq
name: prava_hq
sudoUser: %hq
sudoHost: ALL
sudoCommand: /bin/grep
sudoCommand: /bin/cat
sudoCommand: /usr/bin/id
sudoOption: !authenticate
EOF
ldbadd -H /var/lib/samba/private/sam.ldb sudoRole-object.ldif
echo -e "dn: CN=prava_hq,OU=sudoers,DC=au-team,DC=irpo\nchangetype: modify\nreplace: nTSecurityDescriptor" > ntGen.ldif
ldbsearch  -H /var/lib/samba/private/sam.ldb -s base -b 'CN=prava_hq,OU=sudoers,DC=au-team,DC=irpo' 'nTSecurityDescriptor' | sed -n '/^#/d;s/O:DAG:DAD:AI/O:DAG:DAD:AI\(A\;\;RPLCRC\;\;\;AU\)\(A\;\;RPWPCRCCDCLCLORCWOWDSDDTSW\;\;\;SY\)/;3,$p' | sed ':a;N;$!ba;s/\n\s//g' | sed -e 's/.\{78\}/&\n /g' >> ntGen.ldif
ldbmodify -v -H /var/lib/samba/private/sam.ldb ntGen.ldif
apt-get update && apt-get install ansible -y

cat << EOF >> /etc/ansible/hosts
VMs:
  hosts:
    HQ-SRV:
      ansible_host: 172.16.1.4
      ansible_user: remote_user
      ansible_port: 2026
    HQ-CLI:
      ansible_host: 172.16.1.4
      ansible_user: remote_user
      ansible_port: 2222
    HQ-RTR:
      ansible_host: 192.168.1.1
      ansible_user: net_admin
      ansible_password: P@ssw0rd
      ansible_connection: network_cli
      ansible_network_os: ios
    BR-RTR:
      ansible_host: 192.168.3.1
      ansible_user: net_admin
      ansible_password: P@ssw0rd
      ansible_connection: network_cli
      ansible_network_os: ios
EOF

sed -i '10 a\
ansible_python_interpreter=/usr/bin/python3\
interpreter_python=auto_silent\
ansible_host_key_checking=false' /etc/ansible/ansible.cfg

ssh-keygen -t rsa -b 4096 -N "" -f ~/.ssh/id_rsa -q
apt-get install sshpass -y
grep -q "172.16.1.4:2026" ~/.ssh/known_hosts 2>/dev/null || ssh-keyscan -p 2026 172.16.1.4 >> ~/.ssh/known_hosts
grep -q "172.16.1.4:2222" ~/.ssh/known_hosts 2>/dev/null || ssh-keyscan -p 2222 172.16.1.4 >> ~/.ssh/known_hosts
sshpass -p "P@ssw0rd" ssh-copy-id -p 2026 remote_user@172.16.1.4
sshpass -p "P@ssw0rd" ssh-copy-id -p 2222 remote_user@172.16.1.4

ansible all -m ping
apt-get update && apt-get install -y docker-compose docker-engine
systemctl enable --now docker
mount -o loop /dev/sr0
docker load -i /media/ALTLinux/docker/site_latest.tar
docker load -i /media/ALTLinux/docker/mariadb_latest.tar


cat << EOF >> launch.sh
docker compose -f site.yml up -d 
sleep 5 
docker exec -it db mysql -u root -pPassw0rd -e "
CREATE DATABASE IF NOT EXISTS testdb;

CREATE USER IF NOT EXISTS 'test'@'%' IDENTIFIED BY 'Passw0rd';

GRANT ALL PRIVILEGES ON testdb.* TO 'test'@'%';

FLUSH PRIVILEGES;"
EOF

chmod +x /root/launch.sh
./launch.sh
apt-get install chrony -y
echo -e 'server 172.16.2.5 iburst prefer' > /etc/chrony.conf
systemctl enable --now chronyd
```

### HQ-CLI
```bash
sed -i 's/BOOTPROTO=static/BOOTPROTO=dhcp/' /etc/net/ifaces/ens20/options
systemctl restart network
apt-get update && apt-get install bind-utils -y
system-auth write ad AU-TEAM.IRPO cli AU-TEAM 'administrator' 'P@ssw0rd'
reboot
```
```bash
apt-get install sudo libsss_sudo -y
control sudo public
sed -i '19 a\
sudo_provider = ad' /etc/sssd/sssd.conf
sed -i 's/services = nss, pam/services = nss, pam, sudo/' /etc/sssd/sssd.conf
sed -i '28 a\
sudoers: files sss' /etc/nsswitch.conf
rm -rf /var/lib/sss/db/*
sss_cache -E
systemctl restart sssd
apt-get update && apt-get install nfs-clients -y
mkdir -p /mnt/nfs
cat << EOF >> /etc/fstab
192.168.1.10:/raid/nfs  /mnt/nfs  nfs  intr,soft,_netdev,x-systemd.automount  0  0
EOF
mount -a
mount -v
touch /mnt/nfs/test
apt-get install chrony -y
echo -e 'server 172.16.1.4 iburst prefer' > /etc/chrony.conf
systemctl enable --now chronyd
```
</details>

---

<details>
<summary>SAMBA-DC</summary>

### HQ-SRV

```bash
echo "server=/au-team.irpo/192.168.3.10" >> /etc/dnsmasq.conf
systemctl restart dnsmasq
```

### BR-SRV

```bash
if ! grep -q '^nameserver 8\.8\.8\.8$' /etc/resolv.conf; then
    echo 'nameserver 8.8.8.8' | sudo tee -a /etc/resolv.conf
fi
apt-get update && apt-get install wget dos2unix task-samba-dc -y
sleep 3
echo nameserver 192.168.1.10 >> /etc/resolv.conf
sleep 2
echo 192.168.3.10 br-srv.au-team.irpo >> /etc/hosts
rm -rf /etc/samba/smb.conf
samba-tool domain provision --realm=AU-TEAM.IRPO --domain=AU-TEAM --adminpass=P@ssw0rd --dns-backend=SAMBA_INTERNAL --server-role=dc --option='dns forwarder=192.168.1.10'
mv -f /var/lib/samba/private/krb5.conf /etc/krb5.conf
systemctl enable --now samba.service
samba-tool user add hquser1 P@ssw0rd
samba-tool user add hquser2 P@ssw0rd
samba-tool user add hquser3 P@ssw0rd
samba-tool user add hquser4 P@ssw0rd
samba-tool user add hquser5 P@ssw0rd
samba-tool group add hq
samba-tool group addmembers hq hquser1,hquser2,hquser3,hquser4,hquser5
wget https://raw.githubusercontent.com/sudo-project/sudo/main/docs/schema.ActiveDirectory
dos2unix schema.ActiveDirectory
sed -i 's/DC=X/DC=au-team,DC=irpo/g' schema.ActiveDirectory
head -$(grep -B1 -n '^dn:$' schema.ActiveDirectory | head -1 | grep -oP '\d+') schema.ActiveDirectory > first.ldif
tail +$(grep -B1 -n '^dn:$' schema.ActiveDirectory | head -1 | grep -oP '\d+') schema.ActiveDirectory | sed '/^-/d' > second.ldif
ldbadd -H /var/lib/samba/private/sam.ldb first.ldif --option="dsdb:schema update allowed"=true
ldbmodify -v -H /var/lib/samba/private/sam.ldb second.ldif --option="dsdb:schema update allowed"=true
samba-tool ou add 'ou=sudoers'
cat << EOF > sudoRole-object.ldif
dn: CN=prava_hq,OU=sudoers,DC=au-team,DC=irpo
changetype: add
objectClass: top
objectClass: sudoRole
cn: prava_hq
name: prava_hq
sudoUser: %hq
sudoHost: ALL
sudoCommand: /bin/grep
sudoCommand: /bin/cat
sudoCommand: /usr/bin/id
sudoOption: !authenticate
EOF
ldbadd -H /var/lib/samba/private/sam.ldb sudoRole-object.ldif
echo -e "dn: CN=prava_hq,OU=sudoers,DC=au-team,DC=irpo\nchangetype: modify\nreplace: nTSecurityDescriptor" > ntGen.ldif
ldbsearch  -H /var/lib/samba/private/sam.ldb -s base -b 'CN=prava_hq,OU=sudoers,DC=au-team,DC=irpo' 'nTSecurityDescriptor' | sed -n '/^#/d;s/O:DAG:DAD:AI/O:DAG:DAD:AI\(A\;\;RPLCRC\;\;\;AU\)\(A\;\;RPWPCRCCDCLCLORCWOWDSDDTSW\;\;\;SY\)/;3,$p' | sed ':a;N;$!ba;s/\n\s//g' | sed -e 's/.\{78\}/&\n /g' >> ntGen.ldif
ldbmodify -v -H /var/lib/samba/private/sam.ldb ntGen.ldif
```

### HQ-CLI

```bash
sed -i 's/BOOTPROTO=static/BOOTPROTO=dhcp/' /etc/net/ifaces/ens20/options
systemctl restart network
apt-get update && apt-get install bind-utils -y
system-auth write ad AU-TEAM.IRPO cli AU-TEAM 'administrator' 'P@ssw0rd'
reboot
```
```bash
apt-get install sudo libsss_sudo -y
control sudo public
sed -i '19 a\
sudo_provider = ad' /etc/sssd/sssd.conf
sed -i 's/services = nss, pam/services = nss, pam, sudo/' /etc/sssd/sssd.conf
sed -i '28 a\
sudoers: files sss' /etc/nsswitch.conf
rm -rf /var/lib/sss/db/*
sss_cache -E
systemctl restart sssd
```

> Проверка: в этом же терминале на HQ-CLI прописать `sudo -l -U hquser1`, или на hquser1 использовать `sudo cat /etc/passwd | sudo grep user | sudo id` 
</details>

---

<details>
<summary>Raid</summary>

### HQ-SRV

```bash
mdadm --create /dev/md0 --level=0 --raid-devices=2 /dev/sd[b-c]
mdadm --detail -scan --verbose > /etc/mdadm.conf
apt-get update && apt-get install fdisk -y
fdisk /dev/md0 << EOF
n
p
1
2048
4186111
w
EOF

mkfs.ext4 /dev/md0p1
cat << EOF >> /etc/fstab
/dev/md0p1  /raid  ext4  defaults  0  0
EOF

mkdir /raid
mount -a

apt-get install nfs-server -y
mkdir /raid/nfs
chown 99:99 /raid/nfs
chmod 777 /raid/nfs

cat << EOF >> /etc/exports
/raid/nfs  192.168.2.0/28(rw,sync,no_subtree_check)
EOF
exportfs -a
exportfs -v
systemctl enable nfs
systemctl restart nfs
```

### HQ-CLI

```bash
apt-get update && apt-get install nfs-clients -y
mkdir -p /mnt/nfs
cat << EOF >> /etc/fstab
192.168.1.10:/raid/nfs  /mnt/nfs  nfs  intr,soft,_netdev,x-systemd.automount  0  0
EOF
mount -a
mount -v
touch /mnt/nfs/test
```
</details>

---

<details>
<summary>Chrony</summary>

### ISP

```bash
apt-get install chrony -y
cat << EOF > /etc/chrony.conf
server 127.0.0.1 iburst prefer
hwtimestamp *
local stratum 5
allow 0/0
EOF
systemctl enable --now chronyd
```

### HQ-CLI

```bash
apt-get install chrony -y
echo -e 'server 172.16.1.4 iburst prefer' > /etc/chrony.conf
systemctl enable --now chronyd
```

### HQ-SRV

```bash
apt-get install chrony -y
echo -e 'server 172.16.1.4 iburst prefer' > /etc/chrony.conf
systemctl enable --now chronyd
```

### BR-SRV

```bash
apt-get install chrony -y
echo -e 'server 172.16.2.5 iburst prefer' > /etc/chrony.conf
systemctl enable --now chronyd
```
</details>

---

<details>
<summary>Ansible + Динамическая трансляция портов (Делается только для того, чтобы можно было автоматизировать)</summary>

---

<details>
<summary>Первая версия(Моя, с использованием динамеческого транляции портов)</summary>

### HQ-RTR

```tcl
en
conf
ip nat source static tcp 192.168.1.10 80 172.16.1.4 8080
ip nat source static tcp 192.168.1.10 2026 172.16.1.4 2026
ip nat source static tcp 192.168.2.10 2222 172.16.1.4 2222
end
wr
```

### BR-RTR

```tcl
en
conf
ip nat source static tcp 192.168.3.10 8080 172.16.2.5 8080
ip nat source static tcp 192.168.3.10 2026 172.16.2.5 2026
end
wr
```

### BR-SRV

```bash
apt-get update && apt-get install ansible -y

cat << EOF >> /etc/ansible/hosts
VMs:
  hosts:
    HQ-SRV:
      ansible_host: 172.16.1.4
      ansible_user: remote_user
      ansible_port: 2026
    HQ-CLI:
      ansible_host: 172.16.1.4
      ansible_user: remote_user
      ansible_port: 2222
    HQ-RTR:
      ansible_host: 192.168.1.1
      ansible_user: net_admin
      ansible_password: P@ssw0rd
      ansible_connection: network_cli
      ansible_network_os: ios
    BR-RTR:
      ansible_host: 192.168.3.1
      ansible_user: net_admin
      ansible_password: P@ssw0rd
      ansible_connection: network_cli
      ansible_network_os: ios
EOF

sed -i '10 a\
ansible_python_interpreter=/usr/bin/python3\
interpreter_python=auto_silent\
host_key_checking=false' /etc/ansible/ansible.cfg

ssh-keygen -t rsa -b 4096 -N "" -f ~/.ssh/id_rsa -q
apt-get install sshpass -y
grep -q "172.16.1.4:2026" ~/.ssh/known_hosts 2>/dev/null || ssh-keyscan -p 2026 172.16.1.4 >> ~/.ssh/known_hosts
grep -q "172.16.1.4:2222" ~/.ssh/known_hosts 2>/dev/null || ssh-keyscan -p 2222 172.16.1.4 >> ~/.ssh/known_hosts
sshpass -p "P@ssw0rd" ssh-copy-id -p 2026 remote_user@172.16.1.4
sshpass -p "P@ssw0rd" ssh-copy-id -p 2222 remote_user@172.16.1.4

ansible all -m ping
```
</details>

---

<details>
<summary>Вторая версия(От Ахунова)</summary>

### BR-SRV

```bash
apt-get update && apt-get install ansible sshpass -y
echo -e "[s]\nHQ-SRV ansible_host=192.168.1.10\nHQ-CLI ansible_host=192.168.2.10\n[s:vars]\nansible_user=remote_user\nansible_port=2026\nansible_password=P@ssw0rd\n[r]\nHQ-RTR ansible_host=192.168.1.1\nBR-RTR ansible_host=192.168.3.1\n[r:vars]\nansible_user=net_admin\nansible_password=P@ssw0rd\nansible_connection=network_cli\nansible_network_os=ios" > /etc/ansible/hosts
rm -f /etc/ansible/ansible.cfg
echo -e "[defaults]\ninterpreter_python=auto_silent\nhost_key_checking=false" > /etc/ansible/ansible.cfg
```

</details>

</details>

---

<details>
<summary>Docker</summary>

### BR-SRV

```bash
apt-get update && apt-get install -y docker-compose docker-engine
systemctl enable --now docker
mount -o loop /dev/sr0
docker load -i /media/ALTLinux/docker/site_latest.tar
docker load -i /media/ALTLinux/docker/mariadb_latest.tar


cat << EOF >> launch.sh
docker compose -f site.yml up -d 
sleep 5 
docker exec -it db mysql -u root -pPassw0rd -e "
CREATE DATABASE IF NOT EXISTS testdb;

CREATE USER IF NOT EXISTS 'test'@'%' IDENTIFIED BY 'Passw0rd';

GRANT ALL PRIVILEGES ON testdb.* TO 'test'@'%';

FLUSH PRIVILEGES;"
EOF

chmod +x /root/launch.sh
./launch.sh
```
</details>

---

<details>
<summary>Web-Interface</summary>

### HQ-SRV

```bash
apt-get update
apt-get install apache2 php8.2 apache2-mod_php8.2 mariadb-server php8.2-{opcache,curl,gd,intl,mysqli,xml,xmlrpc,ldap,zip,soap,mbstring,json,xmlreader,fileinfo,sodium} -y

systemctl enable --now httpd2 mariadb

mkdir -p /mnt/additional
mount /dev/sr0 /mnt/additional -o ro

mkdir -p /tmp/web_setup
cp -r /mnt/additional/web/* /tmp/web_setup/

mysql -e "CREATE DATABASE webdb CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
mysql -e "CREATE USER 'webc'@'localhost' IDENTIFIED BY 'P@ssw0rd';"
mysql -e "GRANT ALL PRIVILEGES ON webdb.* TO 'webc'@'localhost';"
mysql -e "FLUSH PRIVILEGES;"

cd /tmp/web_setup

file -i dump.sql

if file -i dump.sql | grep -q "utf-16"; then
    iconv -f UTF-16 -t UTF-8 dump.sql > dump_utf8.sql
    mysql -u root webdb < dump_utf8.sql
else
    mysql -u root webdb < dump.sql
fi

cp index.php /var/www/html/
cp -r logo.png /var/www/html/

chown -R apache2:apache2 /var/www/html
chmod -R 755 /var/www/html

sed -i "s/\$servername = .*;/\$servername = 'localhost';/" /var/www/html/index.php
sed -i "s/\$dbname = .*;/\$dbname = 'webdb';/" /var/www/html/index.php
sed -i "s/\$password = .*;/\$password = 'P@ssw0rd';/" /var/www/html/index.php
sed -i "s/\$username = .*;/\$username = 'webc';/" /var/www/html/index.php

sed -i 's/\tDirectoryIndex index.html index.cgi index.pl index.php index.xhtml index.htm/\tDirectoryIndex index.php index.html index.cgi index.pl index.xhtml index.htm/' /etc/httpd2/conf/mods-enabled/dir.conf
rm -rf /var/www/html/index.html

systemctl restart httpd2

curl -I http://localhost/
```
</details>

---

<details>
<summary>Динамическая трансляция портов(если вы настраивали Ansible по методу Ахунова Вадима, если по моему - пропускайте)</summary>

### HQ-RTR

```tcl
en
conf
ip nat source static tcp 192.168.1.10 80 172.16.1.4 8080
ip nat source static tcp 192.168.1.10 2026 172.16.1.4 2026
ip nat source static tcp 192.168.2.10 2222 172.16.1.4 2222
end
wr
```

### BR-RTR

```tcl
en
conf
ip nat source static tcp 192.168.3.10 8080 172.16.2.5 8080
ip nat source static tcp 192.168.3.10 2026 172.16.2.5 2026
end
wr
```
</details>

---

<details>
<summary>Nginx + Web-Auth</summary>

### ISP

```bash
apt-get install nginx -y
apt-get install apache2-htpasswd -y


htpasswd -bc /etc/nginx/.htpasswd WEB P@ssw0rd

mkdir -p /etc/nginx/sites-available.d
mkdir -p /etc/nginx/sites-enabled.d

cat << EOF > /etc/nginx/sites-available.d/proxy.conf
server {
    listen 80;
    server_name web.au-team.irpo;
    
    auth_basic "Restricted Access";
    auth_basic_user_file /etc/nginx/.htpasswd;
    
    location / {
        proxy_pass http://172.16.1.4:8080;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }
}

server {
    listen 80;
    server_name docker.au-team.irpo;
    
    location / {
        proxy_pass http://172.16.2.5:8080;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }
}
EOF


ln -sf /etc/nginx/sites-available.d/proxy.conf /etc/nginx/sites-enabled.d/

nginx -t
systemctl enable --now nginx
systemctl restart nginx
```
</details>
