# Преднастройка

## HQ-RTR | BR-RTR (Ecorouter)

- Базовая коммутация до ISP-a.

<span style="color:white">Название пользователя: admin, пароль: admin</span>

### HQ-RTR

```tcl
en
conf t
interface int0
description "to isp"
ip address 172.16.4.4/28
exit
port te0
service-instance te0/int0
encapsulation untagged
exit
exit
interface int0
connect port te0 service-instance te0/int0
exit
ip route 0.0.0.0 0.0.0.0 172.16.5.1
exit
wr
```

### BR-RTR

```tcl
en
conf t
interface int0
description "to isp"
ip address 172.16.5.5/28
exit
port te0
service-instance te0/int0
encapsulation untagged
exit
exit
interface int0
connect port te0 service-instance te0/int0
exit
ip route 0.0.0.0 0.0.0.0 172.16.5.1
exit
wr
```

- Создание пользователей admin для ssh.

### HQ-RTR

```tcl
username net_admin
password P@ssw0rd
role admin
end
wr
```

### BR-RTR

```tcl
username net_admin
password P@ssw0rd
role admin
end
wr
```

## HQ-SRV | HQ-CLI | BR-SRV

- Базовая коммутация до роутеров.

-# Название пользователя: root|user, Пароль: toor|resu (На HQ-SRV|BR-SRV root, на HQ-CLI user)

### HQ-SRV

```bash
mkdir -p /etc/net/ifaces/ens20
echo -e "DISABLED=no\nTYPE=eth\nBOOTPROTO=static\nCONFIG_IPv4=yes" > /etc/net/ifaces/ens20/options
echo "192.168.1.10/26" > /etc/net/ifaces/ens20/ipv4address
echo "default via 192.168.1.1" > /etc/net/ifaces/ens20/ipv4route
systemctl restart network
```

### HQ-CLI

```bash
mkdir -p /etc/net/ifaces/ens20
echo -e "DISABLED=no\nTYPE=eth\nBOOTPROTO=static\nCONFIG_IPv4=yes" > /etc/net/ifaces/ens20/options
echo "192.168.2.10/28" > /etc/net/ifaces/ens20/ipv4address
echo "default via 192.168.2.1" > /etc/net/ifaces/ens20/ipv4route
systemctl restart network
```

### BR-SRV

```bash
mkdir -p /etc/net/ifaces/ens20
echo -e "DISABLED=no\nTYPE=eth\nBOOTPROTO=static\nCONFIG_IPv4=yes" > /etc/net/ifaces/ens20/options
echo "192.168.3.10/27" > /etc/net/ifaces/ens20/ipv4address
echo "default via 192.168.3.1" > /etc/net/ifaces/ens20/ipv4route
systemctl restart network
```

- Добавление пользователя user в группу wheel и уравнение прав на уровне root-a

### BR-SRV | HQ-SRV

```bash
visudo
# Пишите 123, потом Shift+G > Стрелка вправо > Нажать "D" затем стрелка влево > :wq
gpasswd -a "user" wheel
```

### HQ-CLI

```bash
# После авторизации ПКМ > Терминал > su- > toor(пароль)
visudo
# Пишите 97, потом Shift+G > Стрелка вправо > Нажать "D" затем стрелка влево > :wq
gpasswd -a "user" wheel
```

## ISP

- Настройка DHCP интерфейса

```bash
mkdir -p /etc/net/ifaces/ens20
echo -e "DISABLED=no\nTYPE=eth\nBOOTPROTO=dhcp\nCONFIG_IPv4=yes" > /etc/net/ifaces/ens20/options
echo "net.ipv4.ip_forward = 1" >> /etc/net/sysctl.conf
systemctl restart network
```

# Инструкция для активации ISP-a

Placeholder.

```bash
apt-get update && apt-get install git -y && git clone https://github.com/NiKeNO1540/DEMO-2025-TESTING
```
