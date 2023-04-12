#! /bin/bash
# Exit if any of the intermediate steps fail
set -e

CONFIG_CONTEXT=$(kubectl --kubeconfig "$1" config current-context)

jq -n --arg k8s_config_context "$CONFIG_CONTEXT" '{"k8s_config_context":$k8s_config_context}'