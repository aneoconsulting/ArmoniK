#! /bin/sh

set -ex
curl -sfL https://get.k3s.io | sh -s - --write-kubeconfig-mode 644 --docker --write-kubeconfig ~/.kube/config
