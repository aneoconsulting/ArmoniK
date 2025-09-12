#! /bin/sh
# This script is used to install k3s.

K3S_DEFAULT_KUBECONFIG=/etc/rancher/k3s/k3s.yaml
TARGET_KUBECONFIG=$HOME/.kube/config

set -ex
curl -sfL https://get.k3s.io | sh -s - --write-kubeconfig-mode 644 --docker --write-kubeconfig $TARGET_KUBECONFIG --kubelet-arg cgroup-driver=systemd

# Ensure that the target kubecondig gets properly updated after each installation
mkdir -p $HOME/.kube
if [ -f $K3S_DEFAULT_KUBECONFIG ]; then
  # Copy default config to the target config only if the first one
  # is newer than the target or if the target config does not exist
  sudo cp -u $K3S_DEFAULT_KUBECONFIG $TARGET_KUBECONFIG
  sudo chmod 644 $TARGET_KUBECONFIG
else
  echo "Error: Default kubeconfig not found at $K3S_DEFAULT_KUBECONFIG."
  echo "Either it has not been created or its default location has changed. Check the k3s documentation"
  exit 1
fi

# To uninstall
# sudo /usr/local/bin/k3s-uninstall.sh
