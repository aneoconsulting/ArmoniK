#! /usr/bin/env bash

# Kubernetes Config Context Retrieval Script
#
# Purpose:
# This script retrieves the current Kubernetes context from a specified kubeconfig file.
# It outputs the context in JSON format, which can be useful for integration with other
# tools or scripts.
#
# Usage:
# ./script.sh <kubeconfig_file>
#
# Parameters:
# - kubeconfig_file: The path to the kubeconfig file from which to retrieve the current
#   Kubernetes context. This path can be an absolute or relative path.
#
# Process:
# 1. The script evaluates the provided kubeconfig file location, expanding any necessary
#    variables.
# 2. It retrieves the current Kubernetes context using the specified kubeconfig file.
# 3. Finally, it outputs the current context in JSON format using jq.
#
# Requirements:
# - kubectl must be installed and configured to interact with the Kubernetes cluster.
# - jq must be installed for formatting the output as JSON.

# Exit if any of the intermediate steps fail
set -e

eval "kubefilelocation=$1" # ~ expand does not work in terraform so we expend it manually
CONFIG_CONTEXT="$(kubectl --kubeconfig "$kubefilelocation" config current-context)"

jq -n --arg k8s_config_context "$CONFIG_CONTEXT" '{"k8s_config_context":$k8s_config_context}'
