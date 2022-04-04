# Local Docker and Kubernetes installation

Instructions to install Docker and Kubernetes on local Linux machine 

You can use [K3s Lightweight Kubernetes](https://rancher.com/docs/k3s/latest/en/) on Linux OS.

## Install Docker

To install Docker, you can follow the instructions presented [here](https://docs.docker.com/engine/install/) for each distribution.

## Install Kubernetes

Install K3s as follows:

```bash
curl -sfL https://get.k3s.io | sh -s - --write-kubeconfig-mode 644 --docker --write-kubeconfig ~/.kube/config
```

## Uninstall Kubernetes

To uninstall k3s on your local machine or a VM, use the following command:

```bash
/usr/local/bin/k3s-uninstall.sh
```