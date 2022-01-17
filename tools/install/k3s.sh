#!/bin/bash

set -ex
curl -sfL https://get.k3s.io | sh -s - --write-kubeconfig-mode 644 --docker
mkdir -p ~/.kube
cp /etc/rancher/k3s/k3s.yaml ~/.kube/config