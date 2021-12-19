#!/bin/bash

set -ex
curl -sfL https://get.k3s.io | sh -s - --docker
sudo chmod 644 /etc/rancher/k3s/k3s.yaml
mkdir -p ~/.kube
cp /etc/rancher/k3s/k3s.yaml ~/.kube/config