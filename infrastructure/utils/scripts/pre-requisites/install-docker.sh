#!/bin/bash
# This script is used to install docker

# FIXME: This does not work
# Search how to install docker on ubuntu20 or 22


# https://docs.docker.com/engine/install/ubuntu/
sudo apt-get remove docker docker-engine docker.io containerd runc

sudo apt-get update

sudo apt install -y ca-certificates curl gnupg

sudo install -m 0755 -d /etc/apt/keyrings

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

sudo chmod a+r /etc/apt/keyrings/docker.gpg

sudo echo "deb [arch=$(dpkg --print-architecture)] https://download.docker.com/linux/${ID} ${VERSION_CODENAME} stable" | tee /etc/apt/sources.list.d/docker.list

sudo apt update

sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
