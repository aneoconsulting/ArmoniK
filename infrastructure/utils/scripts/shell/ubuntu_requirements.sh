#!/usr/bin/bash
# usage: $0 <username>

# TODO: rename this script to ubuntu_pre_requsites_install.sh and add more explicit comments
# We need to know how we want to name these.

if [ -z "$1" ]; then
    echo "Usage: $0 <username>"
    exit 1
fi

set -e

apt update
apt -y dist-upgrade
apt -y install lsb-release jq make git python3-pip
ln -s /usr/bin/python3 /usr/bin/python

# TODO: add docker install
# TODO: add pip packages install
# TODO: add kubectl install
# TODO: add terraform install

# Create docker group and add user
echo "Create docker group and add user " $1
addgroup docker
adduser $1 docker
