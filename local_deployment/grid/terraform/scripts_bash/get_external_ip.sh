#!/bin/bash

# Exit if any of the intermediate steps fail
set -e

EXTERNAL_IP=$(ip route get "1.2.3.4" | awk '{print $7}' | head -1)

jq -n --arg external_ip "$EXTERNAL_IP" '{"external_ip":$external_ip}'