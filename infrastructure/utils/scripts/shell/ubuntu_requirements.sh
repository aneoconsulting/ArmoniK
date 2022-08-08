#!/usr/bin/bash
# usage: $0 <username>

if [ -z "$1" ]; then
    echo "Usage: $0 <username>"
    exit 1
fi

set -e

apt update
apt -y dist-upgrade
apt -y install lsb-release
apt -y install jq
apt -y install make
apt -y install git
apt -y install python3-pip
ln -s /usr/bin/python3 /usr/bin/python

# Create docker group and add user
echo "Create docker group and add user " $1
addgroup docker
adduser $1 docker


