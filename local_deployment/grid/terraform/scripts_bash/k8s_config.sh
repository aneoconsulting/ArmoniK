#! /bin/bash
# Delete existing config
sed -i -e '/k8s_config_\(context\|path\)/d;$a\' parameters.auto.tfvars

# Check the OS
unameOut="$(uname -a)"
case "${unameOut}" in
    *Microsoft*)     OS="WSL";; #must be first since Windows subsystem for linux will have Linux in the name too
    *microsoft*) # inside WSL2 (WARNING: My v2 uses ubuntu 20.4 at the moment slightly different name may not always work)
        if [ "$INSIDE_GENIE" = true -o "$(ps -q 1 -o comm=)" = systemd ]; then
            OS="Linux"
        else
            OS="WSL2"
        fi
        ;;
    Linux*)     OS="Linux";;
    Darwin*)    OS="Mac";;
    *)          OS="UNKNOWN:${unameOut}"
esac

case "$OS" in
    WSL)
        echo "Error: You need to update to WSL2 in Windows" >&2
        exit 1
        ;;
    WSL2)
        {
            echo 'k8s_config_context = "docker-desktop"'
            echo 'k8s_config_path = "~/.kube/config"'
        } >> parameters.auto.tfvars
        ;;
    Linux)
        {
            echo 'k8s_config_context = "default"'
            echo 'k8s_config_path = "/etc/rancher/k3s/k3s.yaml"'
        } >> parameters.auto.tfvars
        ;;
esac
