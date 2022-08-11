#!/bin/bash
# usage: armonik_requirements.sh <username> <k3s_version>

set -e

# Install gpg to add needed repositories
apt -y install gnupg2

# install the pre-requisite need for ArmoniK (docker, k3s, terraform)

# docker
source /etc/os-release
curl -fsSL https://download.docker.com/linux/${ID}/gpg | apt-key add -
echo "deb [arch=$(dpkg --print-architecture)] https://download.docker.com/linux/${ID} ${VERSION_CODENAME} stable" | tee /etc/apt/sources.list.d/docker.list
apt update
apt dist-upgrade -y
apt -y install docker-ce docker-ce-cli containerd.io

# Installation k3s
curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION=$2 sh -s - --write-kubeconfig-mode 644 --docker --write-kubeconfig ~/.kube/config
# copy k3s config file from /root to /home/$USER
cp -r $HOME/.kube /home/$1
chown -R $1:$1 /home/$1/.kube

#terraform
curl -fsSL https://apt.releases.hashicorp.com/gpg | apt-key add -
apt-add-repository "deb [arch=$(dpkg --print-architecture)] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
apt update
apt -y install terraform

# dotnet 6.0 installation
apt -y install dotnet-sdk-6.0
