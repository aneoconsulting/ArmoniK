#!/bin/bash
# This script is used to install k3s.

curl -sfL https://get.k3s.io |sh -s - --write-kubeconfig-mode 644 --docker --write-kubeconfig ~/.kube/config

# To uninstall
# sudo /usr/local/bin/k3s-uninstall.sh
