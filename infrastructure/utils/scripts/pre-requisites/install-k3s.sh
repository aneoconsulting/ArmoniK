#!/bin/bash
# This script is used to install k3s.

curl -sfL https://get.k3s.io | sh -s - --write-kubeconfig-mode 644 --docker --write-kubeconfig ~/.kube/config
# FIXME: does not work for 20.04
# Could come from the genie installation
