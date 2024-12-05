#!/bin/bash
echo "Début de l'installation des versions de Java pour Minecraft..."
sudo apt update && sudo apt upgrade -y
sudo apt install -y software-properties-common
sudo add-apt-repository ppa:adoptopenjdk/ppa
sudo apt update
echo "Installation de Java 8..."
sudo apt install adoptopenjdk-8-hotspot -y
echo "Installation de Java 11..."
sudo apt install adoptopenjdk-11-hotspot -y
echo "Installation de Java 16..."
sudo apt install adoptopenjdk-16-hotspot -y
echo "Installation de Java 17..."
sudo apt install adoptopenjdk-17-hotspot -y
echo "Vérification des versions de Java installées..."
java -version
javac -version

echo "Définition de Java 17 comme version par défaut..."
sudo update-alternatives --config java

# Afficher un message de fin
echo "Installation des versions de Java terminée avec succès !"
echo "Vous pouvez maintenant exécuter Minecraft avec la version de Java de votre choix."
