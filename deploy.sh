#!/bin/bash

echo "=========== Initiating Build Process ==================="
# Installing required utilities and tools.
sudo apt update -y
sudo apt-get install ca-certificates curl gnupg -y
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg
echo   "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" |   sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update -y

echo "================= Installing Docker ===================="
# Installing Docker and its related utilities.
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y
sudo usermod -aG docker ubuntu
sudo mkdir /opt/app
sudo mkdir /opt/info
sudo chown -R ubuntu:ubuntu /opt/app
sudo chown -R ubuntu:ubuntu /opt/info

cd /opt/app/devops-build

echo "=============== Building Docker Image ==================="
# Creating dockerfile and nginx.conf  for the application build process.
./build.sh

echo "=============== Build Process Complete ==================="
echo "Image Details:"
sudo docker image ls

echo "=============== Deploying the Application ==================="
# Deploying the application using docker-compose.
sudo docker compose -f compose.yaml up -d
echo "=============== Deployment Complete ==================="
echo "Application is now running and accessible on port 80."

