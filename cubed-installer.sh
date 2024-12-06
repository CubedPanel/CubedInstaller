#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

sudo apt update && sudo apt full-upgrade -y
sudo apt install -y php php-cli php-fpm php-mysql php-xml php-mbstring php-json composer git php-yaml mariadb-server mariadb-client
sudo systemctl start mariadb
sudo systemctl enable mariadb

read -s -p "Mot de passe pour la base de données : " db_password
sudo mysql -e "SET PASSWORD FOR 'root'@'localhost' = PASSWORD('${db_password}');"
sudo mysql -e "CREATE USER 'root'@'%' IDENTIFIED BY '${db_password}';"
sudo mysql -e "GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION;"
sudo mysql -e "FLUSH PRIVILEGES;"
sudo mysql -e "CREATE DATABASE panel;"
sudo mysql -e "USE panel; CREATE TABLE admins (id INT AUTO_INCREMENT PRIMARY KEY, email VARCHAR(255), password VARCHAR(255));"
sudo mysql -e "USE panel; CREATE TABLE informations (id INT AUTO_INCREMENT PRIMARY KEY, panel_name VARCHAR(255));"
sudo mysql -e "USE panel; CREATE TABLE ports (id INT AUTO_INCREMENT PRIMARY KEY, port INT);"

while true; do
    read -p "Email de l'administrateur : " admin_email
    read -s -p "Mot de passe de l'administrateur : " admin_password
    echo
    read -s -p "Confirmez le mot de passe : " admin_password_confirm
    echo
    if [ "$admin_password" == "$admin_password_confirm" ]; then
        hashed_password=$(echo -n "$admin_password" | sha256sum | awk '{print $1}')
        sudo mysql -e "USE panel; INSERT INTO admins (email, password) VALUES ('${admin_email}', '${hashed_password}');"
        break
    fi
done

read -p "Nom du panel : " panel_name
sudo mysql -e "USE panel; INSERT INTO informations (panel_name) VALUES ('${panel_name}');"

read -p "Port de début (par défaut : 100) : " start_port
start_port=${start_port:-100}
read -p "Port de fin (par défaut : 500) : " end_port
end_port=${end_port:-500}

sql_values=""
for port in $(seq $start_port $end_port); do
    sql_values+="(${port}),"
done
sql_values=${sql_values%,}
sudo mysql -e "USE panel; INSERT INTO ports (port) VALUES ${sql_values};"

sudo iptables -A INPUT -p tcp --dport ${start_port}:${end_port} -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 80 -j ACCEPT

[ ! -d "/etc/iptables" ] && sudo mkdir -p /etc/iptables
sudo iptables-save > /etc/iptables/rules.v4

[ ! -d "/etc/cubed" ] && sudo mkdir -p /etc/cubed
sudo bash -c "cat > /etc/cubed/config.yml" <<EOF
database:
  host: localhost
  name: panel
  user: root
  password: ${db_password}
EOF

echo -e "${GREEN}Installation terminée.${NC}"
