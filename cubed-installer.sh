#!/bin/bash

echo "Début de l'installation des versions de Java pour Minecraft..."

cd /tmp
wget https://github.com/adoptium/temurin8-binaries/releases/download/jdk8u432-b06/OpenJDK8U-jdk_x64_linux_hotspot_8u432b06.tar.gz
tar -xvzf OpenJDK8U-jdk_x64_linux_hotspot_8u432b06.tar.gz -C /opt/

wget https://github.com/adoptium/temurin11-binaries/releases/download/jdk-11.0.25%2B9/OpenJDK11U-jdk_x64_linux_hotspot_11.0.25_9.tar.gz
tar -xvzf OpenJDK11U-jdk_x64_linux_hotspot_11.0.25_9.tar.gz -C /opt/

wget https://github.com/adoptium/temurin17-binaries/releases/download/jdk-17.0.13%2B11/OpenJDK17U-jdk_ppc64le_linux_hotspot_17.0.13_11.tar.gz
tar -xvzf OpenJDK17U-jdk_ppc64le_linux_hotspot_17.0.13_11.tar.gz -C /opt/

sudo ln -s /opt/OpenJDK8U-jdk_x64_linux_hotspot_8u432b06/bin/java /usr/bin/java8
sudo ln -s /opt/OpenJDK11U-jdk_x64_linux_hotspot_11.0.25_9/bin/java /usr/bin/java11
sudo ln -s /opt/OpenJDK17U-jdk_ppc64le_linux_hotspot_17.0.13_11/bin/java /usr/bin/java17

java -version
javac -version

sudo update-alternatives --config java

echo "Installation des versions de Java terminée avec succès !"
