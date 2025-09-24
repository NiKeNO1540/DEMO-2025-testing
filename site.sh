# Установка необходимых пакетов
apt-get update
apt-get install apache2 php8.2 apache2-mod_php8.2 mariadb-server php8.2-{opcache,curl,gd,intl,mysqli,xml,xmlrpc,ldap,zip,soap,mbstring,json,xmlreader,fileinfo,sodium} -y

# Запуск и включение служб
systemctl enable --now httpd2 mariadb

# Монтирование образа
mkdir -p /mnt/additional
mount /dev/sr0 /mnt/additional -o ro

# Создание рабочей директории
mkdir -p /tmp/web_setup
cp -r /mnt/additional/web/* /tmp/web_setup/

# Настройка MySQL/MariaDB
mysql -e "CREATE DATABASE webdb CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
mysql -e "CREATE USER 'webc'@'localhost' IDENTIFIED BY 'P@ssw0rd';"
mysql -e "GRANT ALL PRIVILEGES ON webdb.* TO 'webc'@'localhost';"
mysql -e "FLUSH PRIVILEGES;"

# Импорт базы данных (обработка кодировки)
cd /tmp/web_setup
# Проверяем кодировку файла
file -i dump.sql

# Если файл в UTF-16 или другой кодировке, конвертируем
if file -i dump.sql | grep -q "utf-16"; then
    iconv -f UTF-16 -t UTF-8 dump.sql > dump_utf8.sql
    mysql -u root webdb < dump_utf8.sql
else
    mysql -u root webdb < dump.sql
fi

# Копирование файлов веб-приложения
cp index.php /var/www/html/
cp -r logo.png /var/www/html/

# Настройка прав доступа
chown -R apache2:apache2 /var/www/html
chmod -R 755 /var/www/html

# Настройка подключения к БД в index.php
# Исправляем учетные данные для подключения
sed -i "s/\$servername = .*;/\$servername = 'localhost';/" /var/www/html/index.php
sed -i "s/\$dbname = .*;/\$dbname = 'webdb';/" /var/www/html/index.php
sed -i "s/\$password = .*;/\$password = 'webc';/" /var/www/html/index.php
sed -i "s/\$username = .*;/\$username = 'P@ssw0rd';/" /var/www/html/index.php

sed -i 's/DirectoryIndex index.html index.cgi index.pl index.php index.xhtml index.htm/DirectoryIndex index.php index.html index.cgi index.pl index.xhtml index.htm/' /etc/httpd2/conf/mods-enabled/dir.conf
rm -rf /var/www/html/index.html

# Перезагрузка Apache
systemctl restart httpd2

# Проверка работоспособности
curl -I http://localhost/
