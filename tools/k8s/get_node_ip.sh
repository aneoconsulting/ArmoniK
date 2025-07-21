#! /bin/sh
# Exit if any of the intermediate steps fail
set -e

NODE_NAME="$(kubectl get pods --selector="service=$1" -n $2 -o custom-columns="NODE:.spec.nodeName" --no-headers=true)"
NODE_IP="$(kubectl get nodes -o wide --no-headers=true | grep -w "$NODE_NAME" | awk '{print $6}')"

jq -n --arg node_ip "$NODE_IP" '{"node_ip":$node_ip}'
