#!/bin/bash
# usage: armonik_requirements.sh <username> <k3s_version>
# TODO: split script in order to install docker, k3s, terraform, dotnet in differents scripts
# TODO: create a script to use all the scripts
# TODO: will be removed

# install the pre-requisite need for ArmoniK (docker, k3s, terraform)


# k3s
# change mode in kubernet installation: https://github.com/k3s-io/k3s/issues/389
#curl -sfL https://get.k3s.io | K3S_KUBECONFIG_MODE="644" sh -s - --disable traefik
curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION=$2 sh -s - --write-kubeconfig-mode 644 --docker --write-kubeconfig ~/.kube/config

# copy k3s config file from /root to /home/$USER
cp -r $HOME/.kube /home/$1
chown -R $1:$1 /home/$1/.kube

systemctl enable k3s
systemctl start k3s
