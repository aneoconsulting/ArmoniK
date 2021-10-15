#! /bin/bash
# Delete existing config
sed -i -e '/k8s_config_context/d;$a\' parameters.auto.tfvars
CONFIG_CONTEXT=$(kubectl config current-context)
echo 'k8s_config_context = "'$CONFIG_CONTEXT'"' >> parameters.auto.tfvars