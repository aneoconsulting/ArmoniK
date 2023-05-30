#!/usr/bin/bash
# usage: $0 <username>

if [ -z "$1" ]; then
    echo "Usage: $0 <username>"
    exit 1
fi

set -e

apt update
apt -y dist-upgrade
apt -y install lsb-release jq make git python3-pip
apt -y install python-is-python3

# dotnet 6.0 installation
apt -y install dotnet-sdk-6.0 dotnet6

# Install gpg to add needed repositories
apt -y install gnupg software-properties-common
apt -y install curl lsb-release software-properties-common apt-transport-https gnupg

# Install docker (from Ubuntu repository)
apt -y install docker.io

## Create docker group and add user
echo "Create docker group and add user " $1
addgroup docker
adduser $1 docker

# To be able to test armonik_core only install just
snap install --edge --classic just
