#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}[!] Mise à jour du système...${NC}"
sudo apt update && sudo apt full-upgrade -y

echo -e "${YELLOW}[?] Installation de PHP, Git, Composer, YAML, et MariaDB...${NC}"
sudo apt install -y php php-cli php-fpm php-mysql php-xml php-mbstring php-json composer git php-yaml mariadb-server mariadb-client unzip wget

echo -e "${GREEN}[+] PHP, Git, Composer, YAML, et MariaDB installés avec succès.${NC}"
sudo systemctl start mariadb
sudo systemctl enable mariadb

echo -e "${YELLOW}[?] Entrez le mot de passe pour la base de données :${NC}"
read -s db_password

echo -e "${BLUE}[!] Configuration de la base de données...${NC}"
sudo mysql -e "SET PASSWORD FOR 'root'@'localhost' = PASSWORD('${db_password}');"
sudo mysql -e "CREATE USER 'root'@'%' IDENTIFIED BY '${db_password}';"
sudo mysql -e "GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION;"
sudo mysql -e "FLUSH PRIVILEGES;"
sudo mysql -e "CREATE DATABASE panel;"
sudo mysql -e "USE panel; CREATE TABLE admins (id INT AUTO_INCREMENT PRIMARY KEY, email VARCHAR(255), password VARCHAR(255));"
sudo mysql -e "USE panel; CREATE TABLE informations (id INT AUTO_INCREMENT PRIMARY KEY, panel_name VARCHAR(255));"
sudo mysql -e "USE panel; CREATE TABLE ports (id INT AUTO_INCREMENT PRIMARY KEY, port INT);"

echo -e "${YELLOW}[?] Entrez l'email de l'administrateur :${NC}"
read admin_email
echo -e "${YELLOW}[?] Entrez le mot de passe de l'administrateur :${NC}"
read -s admin_password
echo -e "${YELLOW}[?] Confirmez le mot de passe de l'administrateur :${NC}"
read -s admin_password_confirm

while [ "$admin_password" != "$admin_password_confirm" ]; do
    echo -e "${RED}[!] Les mots de passe ne correspondent pas. Réessayez.${NC}"
    echo -e "${YELLOW}[?] Entrez le mot de passe de l'administrateur :${NC}"
    read -s admin_password
    echo -e "${YELLOW}[?] Confirmez le mot de passe de l'administrateur :${NC}"
    read -s admin_password_confirm
done

hashed_password=$(echo -n "$admin_password" | sha256sum | awk '{print $1}')
sudo mysql -e "USE panel; INSERT INTO admins (email, password) VALUES ('${admin_email}', '${hashed_password}');"

echo -e "${YELLOW}[?] Entrez le nom du panel :${NC}"
read panel_name
sudo mysql -e "USE panel; INSERT INTO informations (panel_name) VALUES ('${panel_name}');"

echo -e "${YELLOW}[?] Entrez le port de début (par défaut : 100) :${NC}"
read start_port
start_port=${start_port:-100}

echo -e "${YELLOW}[?] Entrez le port de fin (par défaut : 500) :${NC}"
read end_port
end_port=${end_port:-500}

sql_values=""
for port in $(seq $start_port $end_port); do
    sql_values+="(${port}),"
done
sql_values=${sql_values%,}
sudo mysql -e "USE panel; INSERT INTO ports (port) VALUES ${sql_values};"

echo -e "${BLUE}[!] Configuration des règles iptables...${NC}"
sudo iptables -A INPUT -p tcp --dport ${start_port}:${end_port} -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 80 -j ACCEPT

[ ! -d "/etc/iptables" ] && sudo mkdir -p /etc/iptables
sudo iptables-save > /etc/iptables/rules.v4

echo -e "${YELLOW}[?] Création du fichier de configuration /etc/cubed/config.yml...${NC}"
[ ! -d "/etc/cubed" ] && sudo mkdir -p /etc/cubed
sudo bash -c "cat > /etc/cubed/config.yml" <<EOF
database:
  host: localhost
  name: panel
  user: root
  password: ${db_password}
EOF

echo -e "${GREEN}[+] Configuration de la base de données terminée.${NC}"

echo -e "${YELLOW}[?] Téléchargement de CubedPanel...${NC}"
wget -q https://github.com/CubedPanel/CubedPanel/archive/refs/heads/main.zip -O /tmp/cubedpanel.zip

echo -e "${RED}[!] Suppression de index.html...${NC}"
sudo rm -f /var/www/html/index.html

echo -e "${YELLOW}[?] Extraction de CubedPanel dans /var/www/html${NC}"
sudo unzip -o /tmp/cubedpanel.zip -d /var/www/html
sudo mv /var/www/html/CubedPanel-main/* /var/www/html/
sudo rm -rf /tmp/cubedpanel.zip

echo -e "${GREEN}[+] Installation terminée avec succès.${NC}"
