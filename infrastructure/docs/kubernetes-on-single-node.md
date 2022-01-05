# Table of contents

1. [Introduction](#introduction)
2. [Install Kubernetes](#install-kubernetes)
3. [Install Docker](#install-docker)
4. [Uninstall Kubernetes](#uninstall-kubernetes)

# Introduction <a name="introduction"></a>

Instructions to install Kubernetes on local Linux machine or Windows machine on [WSL 2](./wsl2.md).

You can use [K3s Lightweight Kubernetes](https://rancher.com/docs/k3s/latest/en/) on Linux OS.

# Install Docker <a name="install-docker"></a>

To install docker, you can follow the instructions presented [here](https://docs.docker.com/engine/install/) for each
distribution.

# Install Kubernetes <a name="install-kubernetes"></a>

Install K3s as follows:

```bash
curl -sfL https://get.k3s.io | sh -s - --write-kubeconfig-mode 644
```

***Warning:*** If you want use host's Docker rather than containerd use `--docker` option:

```bash
curl -sfL https://get.k3s.io | sh -s - --write-kubeconfig-mode 644 --docker
```

After the K3s installation, you initialize the configuration file of Kubernetes:

```bash
mkdir -p ~/.kube
cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
```

# Uninstall Kubernetes <a name="uninstall-kubernetes"></a>

To uninstall k3s on your local machine or a VM, use the following command:

```bash
/usr/local/bin/k3s-uninstall.sh
```
