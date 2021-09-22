#!/bin/bash
unameOut=$(uname -a)
case "${unameOut}" in
    *Microsoft*)     OS="WSL";; #must be first since Windows subsystem for linux will have Linux in the name too
    *microsoft*)     OS="WSL2";; #WARNING: My v2 uses ubuntu 20.4 at the moment slightly different name may not always work
    Linux*)     OS="Linux";;
    Darwin*)    OS="Mac";;
    *)          OS="UNKNOWN:${unameOut}"
esac
if [[ "$OS" = ^WSL ]]; then
    echo " You need to Update to WSL2 in Windows"
elif [[ "$OS" =~ ^WSL2 ]]; then
    rm  ../local_deployment/grid/terraform/parameters.auto.tfvars 
    echo "
# Copyright 2021 Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
# Licensed under the Apache License, Version 2.0 https://aws.amazon.com/apache-2-0/

region = \"eu-west-1\"
dynamodb_port = 8000
local_services_port = 8001
redis_port = 6379
redis_port_without_ssl = 7777
### LINUX
//k8s_config_context = \"default\"
//k8s_config_path = \"/etc/rancher/k3s/k3s.yaml\"
### WINDOWS
k8s_config_context = \"docker-desktop\"
k8s_config_path = \"~/.kube/config\"
redis_with_ssl = true
connection_redis_timeout = 10000
redis_ca_cert = \"/redis_certificates/ca.crt\"
redis_client_pfx = \"/redis_certificates/certificate.pfx\"
redis_key_file = \"/redis_certificates/redis.key\"
redis_cert_file = \"/redis_certificates/redis.crt\"
cluster_config = \"local\"
image_pull_policy = \"IfNotPresent\"
"  >> ../local_deployment/grid/terraform/parameters.auto.tfvars
fi

