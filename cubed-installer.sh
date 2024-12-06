#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

sudo apt update && sudo apt full-upgrade -y
echo -e "${YELLOW}[?] Installation de PHP...${NC}"
sudo apt install -y php php-cli php-fpm php-mysql php-xml php-mbstring php-json php-yaml unzip curl git
php_version=$(php -v | head -n 1)
echo -e "${GREEN}PHP installé avec succès : $php_version${NC}"

sudo apt install -y iptables mariadb-server mariadb-client
sudo systemctl start mariadb
sudo systemctl enable mariadb

echo -e "${YELLOW}[?] Que voulez-vous comme mot de passe pour la base de données ?${NC}"
read -s db_password
echo -e "${YELLOW}[?] Confirmez le mot de passe de la base de données :${NC}"
read -s db_password_confirm

if [ "$db_password" != "$db_password_confirm" ]; then
    echo -e "${RED}Les mots de passe ne correspondent pas. Veuillez réessayer.${NC}"
    exit 1
fi

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

echo -e "${YELLOW}[?] Entrez le port de début (par défaut : 100) :${NC}"
read start_port
start_port=${start_port:-100}

echo -e "${YELLOW}[?] Entrez le port de fin (par défaut : 500) :${NC}"
read end_port
end_port=${end_port:-500}

for port in $(seq $start_port $end_port); do
    sql_values=""

    for port in $(seq $start_port $end_port); do
        sql_values+="(${port}),"
    done
    sql_values=${sql_values%,}

    sudo mysql -e "USE panel; INSERT INTO ports (port) VALUES ${sql_values};"
    sudo iptables -A INPUT -p tcp --dport ${start_port}:${end_port} -j ACCEPT
    sudo iptables -A INPUT -p tcp --dport 80 -j ACCEPT
done

if [ ! -d "/etc/iptables" ]; then
    sudo mkdir -p /etc/iptables
fi
sudo iptables-save > /etc/iptables/rules.v4

sudo rm -f /var/www/html/index.html

echo -e "${YELLOW}[?] Téléchargement de CubedPanel...${NC}"
wget -q https://github.com/CubedPanel/CubedPanel/archive/refs/heads/main.zip -O /tmp/cubedpanel.zip
sudo unzip -o /tmp/cubedpanel.zip -d /var/www/html
sudo rm -f /tmp/cubedpanel.zip

echo -e "${YELLOW}[?] Création du fichier composer.json...${NC}"
cat > /var/www/html/composer.json <<EOL
{
    "name": "cubedpanel/cubedpanel",
    "description": "CubedPanel Web Panel",
    "type": "project",
    "require": {
        "php": ">=7.4",
        "ext-json": "*",
        "ext-mbstring": "*",
        "ext-xml": "*",
        "symfony/yaml": "^5.0"
    },
    "autoload": {
        "psr-4": {
            "CubedPanel\\\\": "src/"
        }
    }
}
EOL

echo -e "${YELLOW}[?] Installation des dépendances Composer...${NC}"
cd /var/www/html
curl -sS https://getcomposer.org/installer | php
sudo mv composer.phar /usr/local/bin/composer

sudo composer install

echo -e "${YELLOW}[?] Création du fichier /etc/cubed/config.yml...${NC}"
sudo mkdir -p /etc/cubed
cat > /etc/cubed/config.yml <<EOL
database:
  host: "localhost"
  username: "root"
  password: "${db_password}"
  database: "panel"
  port: "3306"
EOL

echo -e "${GREEN}Installation terminée avec succès.${NC}"
