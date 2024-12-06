#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}[?] Désinstallation de CubedPanel...${NC}"

sudo rm -rf /var/www/html/*
sudo rm -f /etc/cubed/config.yml

sudo apt-get remove --purge -y php* mariadb-server mariadb-client iptables unzip git curl composer
sudo apt-get autoremove --purge -y

sudo iptables -F
sudo rm -f /etc/iptables/rules.v4

sudo mysql -e "DROP DATABASE IF EXISTS panel;"
sudo mysql -e "DROP USER IF EXISTS 'root'@'localhost';"
sudo mysql -e "DROP USER IF EXISTS 'root'@'%';"

sudo rm -f /usr/local/bin/composer

sudo rm -f /var/www/html/index.html

echo -e "${GREEN}Désinstallation terminée avec succès.${NC}"
