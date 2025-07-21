#! /usr/bin/env bash
# Exit if any of the intermediate steps fail
set -e

eval "kubefilelocation=$1" # ~ expand does not work in terraform so we expend it manually
CONFIG_CONTEXT="$(kubectl --kubeconfig "$kubefilelocation" config current-context)"

jq -n --arg k8s_config_context "$CONFIG_CONTEXT" '{"k8s_config_context":$k8s_config_context}'
