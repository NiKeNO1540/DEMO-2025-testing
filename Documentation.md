# Документация по настройке стенда

## Содержание
1. [Преднастройка](#преднастройка)
2. [Настройка ALTPve](#настройка-altpve)
3. [Настройка маршрутизаторов](#настройка-маршрутизаторов)
4. [Настройка серверов и клиентов](#настройка-серверов-и-клиентов)
5. [Настройка ISP](#настройка-isp)
6. [Активация ISP](#активация-isp)

## Преднастройка

### Топология сети
```
ISP (172.16.1.1/28) <---> HQ-RTR (172.16.1.4/28) <---> HQ-SRV (192.168.1.10/27)
                                                      ↳ HQ-CLI (192.168.2.10/28)
                     
ISP (172.16.2.1/28) <---> BR-RTR (172.16.2.5/28) <---> BR-SRV (192.168.3.10/28)
```

## Настройка ALTPve

### Монтирование образа

1. **Доступ к интерфейсу ALTPve**
   - Перейдите по IP-адресу, назначаемому машиной ALTPve
   - Перейдите в раздел: **Хранилище** → **ISO Образы**

   ![Интерфейс ALTPve](https://github.com/user-attachments/assets/a4083415-18cf-4e71-a51f-33dbeaa14109)

2. **Загрузка образа**
   - Нажмите кнопку **"Загрузить"**
   - Выберите образ `Additional.iso`

   ![Загрузка образа](https://github.com/user-attachments/assets/cf1eceba-1da3-482c-908e-2d96df4433c7)

3. **Монтирование образа**
   - Выберите целевую машину (`HQ-SRV` или `BR-SRV`)
   - Перейдите в **Hardware** → **Add** → **CD/DVD Drive**
   - Настройте как показано на скриншоте → **"OK"**

   ![Монтирование образа](https://github.com/user-attachments/assets/51cdb935-2c1a-4e8d-b71c-160bef934173)

### Добавление дисков для RAID

1. **Добавление дисков в PVE**
   - Перейдите: **PVE** → **HQ-SRV** → **Hardware** → **Add** → **Hard Disk**
   - В поле **Storage** выберите `local`
   - Установите размер диска: `1 GB`
   - Добавьте **2 диска** с одинаковыми параметрами

   ![Добавление дисков](https://github.com/user-attachments/assets/7e654fa2-ff0b-4521-9697-baffeab4a304)

## Настройка маршрутизаторов

### Учетные данные по умолчанию
- **Имя пользователя:** `admin`
- **Пароль:** `admin`

### HQ-RTR

```tcl
enable
configure terminal
interface int0
description "to isp"
ip address 172.16.1.4/28
exit
port te0
service-instance te0/int0
encapsulation untagged
exit
exit
interface int0
connect port te0 service-instance te0/int0
exit
ip route 0.0.0.0 0.0.0.0 172.16.1.1
no security default
exit
write memory
```

### BR-RTR

```tcl
enable
configure terminal
interface int0
description "to isp"
ip address 172.16.2.5/28
exit
port te0
service-instance te0/int0
encapsulation untagged
exit
exit
interface int0
connect port te0 service-instance te0/int0
exit
ip route 0.0.0.0 0.0.0.0 172.16.2.1
no security default
exit
write memory
```

## Настройка серверов и клиентов

### Учетные данные по умолчанию

| Устройство | Пользователь | Пароль |
|------------|--------------|---------|
| HQ-SRV     | `root`       | `toor`  |
| BR-SRV     | `root`       | `toor`  |
| HQ-CLI     | `user`       | `resu`  |

### Настройка сетевых интерфейсов

#### HQ-SRV
```bash
mkdir -p /etc/net/ifaces/ens20
cat > /etc/net/ifaces/ens20/options << EOF
DISABLED=no
TYPE=eth
BOOTPROTO=static
CONFIG_IPv4=yes
EOF
echo "192.168.1.10/27" > /etc/net/ifaces/ens20/ipv4address
echo "default via 192.168.1.1" > /etc/net/ifaces/ens20/ipv4route
systemctl restart network
```

#### HQ-CLI
```bash
mkdir -p /etc/net/ifaces/ens20
cat > /etc/net/ifaces/ens20/options << EOF
DISABLED=no
TYPE=eth
BOOTPROTO=static
CONFIG_IPv4=yes
EOF
echo "192.168.2.10/28" > /etc/net/ifaces/ens20/ipv4address
echo "default via 192.168.2.1" > /etc/net/ifaces/ens20/ipv4route
systemctl restart network
```

#### BR-SRV
```bash
mkdir -p /etc/net/ifaces/ens20
cat > /etc/net/ifaces/ens20/options << EOF
DISABLED=no
TYPE=eth
BOOTPROTO=static
CONFIG_IPv4=yes
EOF
echo "192.168.3.10/28" > /etc/net/ifaces/ens20/ipv4address
echo "default via 192.168.3.1" > /etc/net/ifaces/ens20/ipv4route
systemctl restart network
```

### Настройка SSH доступа

> **Примечание по безопасности:** Данная настройка разрешает root-доступ по SSH только в целях автоматизации тестового стенда. В production-среде такая практика не рекомендуется.

#### BR-SRV | HQ-SRV
```bash
echo "PermitRootLogin yes" >> /etc/openssh/sshd_config
echo "Port 2026" >> /etc/openssh/sshd_config
systemctl enable --now sshd
systemctl restart sshd
```

#### HQ-CLI
```bash
echo "PermitRootLogin yes" >> /etc/openssh/sshd_config
echo "Port 2222" >> /etc/openssh/sshd_config
systemctl enable --now sshd
systemctl restart sshd
```

## Настройка ISP

### Базовая конфигурация сети
```bash
mkdir -p /etc/net/ifaces/ens20
cat > /etc/net/ifaces/ens20/options << EOF
DISABLED=no
TYPE=eth
BOOTPROTO=dhcp
CONFIG_IPv4=yes
EOF
echo "net.ipv4.ip_forward = 1" >> /etc/net/sysctl.conf
systemctl restart network
```

## Активация ISP

### Автоматическая настройка
Выполните следующую команду для автоматической настройки ISP:

```bash
apt-get update && \
apt-get install -y git && \
git clone https://github.com/NiKeNO1540/DEMO-2025-testing && \
chmod +x DEMO-2025-testing/Full_Config_Progression_AIO.sh && \
./DEMO-2025-testing/Full_Config_Progression_AIO.sh
```

### Ручная настройка (альтернатива)
Если автоматический скрипт недоступен, выполните настройку вручную согласно разделам выше.

---

## Примечания

- Все команды должны выполняться с соответствующими привилегиями
- Рекомендуется проверить connectivity между узлами после настройки
- Для диагностики используйте команды `ping`, `traceroute`, `ip route`
- SSH порты: HQ-SRV/BR-SRV - 2026, HQ-CLI - 2222
