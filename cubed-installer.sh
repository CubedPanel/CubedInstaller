#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

sudo apt update && sudo apt full-upgrade -y
sudo apt install -y iptables mariadb-server mariadb-client
sudo systemctl start mariadb
sudo systemctl enable mariadb

echo -e "${YELLOW}[?] Que voulez-vous comme mot de passe pour la base de données ?${NC}"
read -s db_password
sudo mysql -e "SET PASSWORD FOR 'root'@'localhost' = PASSWORD('${db_password}');"
sudo mysql -e "CREATE USER 'root'@'%' IDENTIFIED BY '${db_password}';"
sudo mysql -e "GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION;"
sudo mysql -e "FLUSH PRIVILEGES;"

sudo mysql -e "CREATE DATABASE panel;"
sudo mysql -e "USE panel; CREATE TABLE admins (id INT AUTO_INCREMENT PRIMARY KEY, email VARCHAR(255), password VARCHAR(255));"
sudo mysql -e "USE panel; CREATE TABLE informations (id INT AUTO_INCREMENT PRIMARY KEY, panel_name VARCHAR(255));"
sudo mysql -e "USE panel; CREATE TABLE ports (id INT AUTO_INCREMENT PRIMARY KEY, port INT);"

while true; do
    echo -e "${YELLOW}[?] Entrez l'email de l'administrateur :${NC}"
    read admin_email
    echo -e "${YELLOW}[?] Entrez le mot de passe de l'administrateur :${NC}"
    read -s admin_password
    echo -e "${YELLOW}[?] Confirmez le mot de passe de l'administrateur :${NC}"
    read -s admin_password_confirm

    if [ "$admin_password" == "$admin_password_confirm" ]; then
        hashed_password=$(echo -n "$admin_password" | sha256sum | awk '{print $1}')
        sudo mysql -e "USE panel; INSERT INTO admins (email, password) VALUES ('${admin_email}', '${hashed_password}');"
        break
    else
        echo -e "${RED}Les mots de passe ne correspondent pas. Veuillez réessayer.${NC}"
    fi
done

echo -e "${YELLOW}[?] Entrez le nom du panel :${NC}"
read panel_name
sudo mysql -e "USE panel; INSERT INTO informations (panel_name) VALUES ('${panel_name}');"

echo -e "${YELLOW}[?] Entrez le port de début (par défaut : 1000) :${NC}"
read start_port
start_port=${start_port:-1000}

echo -e "${YELLOW}[?] Entrez le port de fin (par défaut : 5000) :${NC}"
read end_port
end_port=${end_port:-5000}

for port in $(seq $start_port $end_port); do
    sudo mysql -e "USE panel; INSERT INTO ports (port) VALUES (${port});"
sudo iptables -A INPUT -p tcp --dport ${start_port}:${end_port} -j ACCEPT
    sudo iptables -A INPUT -p tcp --dport 80 -j ACCEPT
done

if [ ! -d "/etc/iptables" ]; then
    sudo mkdir -p /etc/iptables
fi

sudo iptables-save > /etc/iptables/rules.v4
echo -e "${GREEN}Installation terminée avec succès.${NC}"
