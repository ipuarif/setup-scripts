#!/bin/bash

#Install java
sudo apt update
sudo apt install -y openjdk-17-jdk

curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key \
| sudo tee /usr/share/keyrings/jenkins-keyring.asc > /dev/null
echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
https://pkg.jenkins.io/debian-stable binary/ \
| sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null

# Install jenkins

sudo apt install -y jenkins
sudo systemctl enable jenkins
sudo systemctl start jenkins

## Install docker
sudo apt install -y docker.io
sudo systemctl enable docker
sudo systemctl start docker

sudo usermod -aG docker jenkins
sudo usermod -aG docker ubuntu

sudo systemctl restart jenkins



