#! /bin/sh

# Node IP Retrieval Script
#
# Purpose:
# This script retrieves the IP address of the node on which a specific Kubernetes pod
# is running. It uses the pod's service name and namespace to identify the pod and
# then fetches the corresponding node's IP address.
#
# Usage:
# ./script.sh <service_name> <namespace>
#
# Parameters:
# - service_name: The name of the Kubernetes service associated with the pod.
# - namespace: The namespace in which the service and pod are located.
#
# Process:
# 1. The script retrieves the node name where the pod is running by querying Kubernetes
#    with the specified service name and namespace.
# 2. It then fetches the IP address of the node using the node name.
# 3. Finally, it outputs the node IP address in JSON format.
#
# Requirements:
# - kubectl must be installed and configured to interact with the Kubernetes cluster.
# - jq must be installed for formatting the output as JSON.

# Exit if any of the intermediate steps fail
set -e

NODE_NAME="$(kubectl get pods --selector="service=$1" -n $2 -o custom-columns="NODE:.spec.nodeName" --no-headers=true)"
NODE_IP="$(kubectl get nodes -o wide --no-headers=true | grep -w "$NODE_NAME" | awk '{print $6}')"

jq -n --arg node_ip "$NODE_IP" '{"node_ip":$node_ip}'
