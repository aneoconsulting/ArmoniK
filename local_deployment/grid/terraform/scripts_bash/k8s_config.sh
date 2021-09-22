#!/bin/bash
# Delete existing config
sed -i '/k8s_config_context/d' parameters.auto.tfvars
sed -i '/k8s_config_path/d' parameters.auto.tfvars

# Check the OS
unameOut=$(uname -a)
case "${unameOut}" in
    *Microsoft*)     OS="WSL";; #must be first since Windows subsystem for linux will have Linux in the name too
    *microsoft*)     OS="WSL2";; #WARNING: My v2 uses ubuntu 20.4 at the moment slightly different name may not always work
    Linux*)     OS="Linux";;
    Darwin*)    OS="Mac";;
    *)          OS="UNKNOWN:${unameOut}"
esac

# Set the configuration
if [[ "$OS" = ^WSL ]]; then
    echo " You need to Update to WSL2 in Windows"
elif [[ "$OS" =~ ^WSL2 ]]; then
    echo "
k8s_config_context = \"docker-desktop\"
k8s_config_path = \"~/.kube/config\""  >> parameters.auto.tfvars
elif [[ "$OS" =~ ^Linux ]]; then
    echo "
k8s_config_context = \"default\"
k8s_config_path = \"/etc/rancher/k3s/k3s.yaml\""  >> parameters.auto.tfvars
fi

echo "Configurate kubernetes is SUCCESS"

