# Table of contents

1. [Introduction](#introduction)
2. [Install Kubernetes](#install-kubernetes)
3. [Install Docker](#install-docker)
4. [Uninstall Kubernetes](#uninstall-kubernetes)

# Introduction

Instructions to install Kubernetes on local Linux machine or Windows machine on [WSL 2](wsl2.md).

You can use [K3s Lightweight Kubernetes](https://rancher.com/docs/k3s/latest/en/) on Linux OS.

# Install Docker

To install docker, you can follow the instructions presented [here](https://docs.docker.com/engine/install/) for each
distribution.

# Install Kubernetes

Install K3s as follows:

```bash
curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION="v1.23.8+k3s1" sh -s - --write-kubeconfig-mode 644 --docker --write-kubeconfig ~/.kube/config
```

# Uninstall Kubernetes

To uninstall k3s on your local machine or a VM, use the following command:

```bash
/usr/local/bin/k3s-uninstall.sh
```

### [Return to quick deploy ArmoniK on local machine](../README.md#install-kubernetes)

### [Return to the infrastructure main page](../../../README.md)

### [Return to the project main page](../../../../README.md)
