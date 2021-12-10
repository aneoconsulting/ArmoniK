#!/bin/bash

#get root path of script
cd $(dirname $0)
root_path=$(pwd -P)
wsl_cert_dest="/mnt/wsl/cert"
redis_certificates_path="../redis_certificates"

#########################################################
## NO MORE PATH VARIABLES CAN BE MODIFIED AFTER THIS LINE
#########################################################


#check if it's wsl env
is_wsl=$(grep -qEi "(Microsoft|WSL)" /proc/version; echo $?)

echo "Boostrap for WSL ? $(echo $is_wsl)"

#get absolute path of credentials
cd ${redis_certificates_path}
cert_path=$(pwd -P)
cd ${root_path}


if [ "$is_wsl" == "0" ]; then
    sudo mkdir -p $wsl_cert_dest || true
    if ! grep -qs $wsl_cert_dest /proc/mounts; then
        echo -ne "Mounting certificate volume for WSL2 : "
        sudo mount --bind ${cert_path} $wsl_cert_dest
        err=$?
        if [ "$err" -ne 0 ]; then 
            echo "failure to mount $wsl_cert_dest"
        else
            echo "SUCCESS"
        fi    
    else
        echo "Certificate volume for Wsl2 is already mounted"
    fi
fi