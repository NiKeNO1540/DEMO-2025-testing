#! /bin/bash

apt-get update && apt-get install -y docker-compose docker-engine
systemctl enable --now docker
systemctl status docker
mount -o loop /dev/sr0
docker load -i /media/ALTLinux/docker/site_latest.tar
docker load -i /media/ALTLinux/docker/mariadb_latest.tar

docker compose -f site.yml up -d && sleep 5 && docker exec -it db mysql -u root -pPassw0rd -e "CREATE DATABASE IF NOT EXISTS testdb; CREATE USER 'test'@'%' IDENTIFIED BY 'Passw0rd'; GRANT ALL PRIVILEGES ON testdb.* TO 'test'@'%'; FLUSH PRIVILEGES;"
