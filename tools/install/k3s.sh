#! /bin/sh

set -ex
curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION="v1.23.8+k3s1" sh -s - --write-kubeconfig-mode 644 --docker --write-kubeconfig ~/.kube/config
