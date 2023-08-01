#!/bin/bash
# usage: armonik_requirements.sh <username> <k3s_version>

set -ex

# install the pre-requisite need for ArmoniK not available on Ubuntu 22.04 (k3s, terraform)

# k3s

## change mode in kubernet installation: https://github.com/k3s-io/k3s/issues/389
curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION=$2 sh -s - --write-kubeconfig-mode 644 --docker --write-kubeconfig ~/.kube/config

# copy k3s config file from /root to /home/$USER
cp -r $HOME/.kube /home/$1
chown -R $1:$1 /home/$1/.kube

systemctl enable k3s
systemctl start k3s

# Terraform
curl -fsSL https://apt.releases.hashicorp.com/gpg | apt-key add -
apt-add-repository "deb [arch=$(dpkg --print-architecture)] https://apt.releases.hashicorp.com $(lsb_release -cs) main"

apt update
apt -y install terraform

