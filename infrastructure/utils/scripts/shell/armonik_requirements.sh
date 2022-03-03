#!/bin/bash
# usage: armonik_requirements.sh <username>

set -e

# Install gpg to add needed repositories
apt -y install gnupg2

# install the pre-requisite need for ArmoniK (docker, kubernetes (k3s), terraform)

# docker
source /etc/os-release
curl -fsSL https://download.docker.com/linux/${ID}/gpg | apt-key add -
echo "deb [arch=$(dpkg --print-architecture)] https://download.docker.com/linux/${ID} ${VERSION_CODENAME} stable" | tee /etc/apt/sources.list.d/docker.list
apt update
apt dist-upgrade -y
apt -y install docker-ce docker-ce-cli containerd.io

# k3s
# change mode in kubernet installation: https://github.com/k3s-io/k3s/issues/389
curl -sfL https://get.k3s.io | K3S_KUBECONFIG_MODE="644" sh -s -
mkdir -p $HOME/.kube && cp /etc/rancher/k3s/k3s.yaml $HOME/.kube/config && export KUBECONFIG=$HOME/.kube/config
systemctl start k3s # optional
systemctl enable k3s # optional

#terraform
curl -fsSL https://apt.releases.hashicorp.com/gpg | apt-key add -
apt-add-repository "deb [arch=$(dpkg --print-architecture)] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
apt update
apt -y install terraform

# dotnet 6.0 installation
apt -y install dotnet-sdk-6.0

# Create data directory (needed by ArmoniK) and give access to user
mkdir -p /data && sudo chown -R $1:$1 /data
chmod a+r /etc/rancher/k3s/k3s.yaml