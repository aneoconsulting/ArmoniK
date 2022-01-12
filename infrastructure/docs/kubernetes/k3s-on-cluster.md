# Table of contents

1. [Introduction](#introduction)
2. [Install Docker](#install-docker)
3. [Install Kubernetes](#install-kubernetes)
    1. [On master node](#on-master-node)
    2. [On worker nodes](#on-worker-nodes)
4. [Accessing the cluster from outside](#accessing-the-cluster-from-outside)
5. [Uninstall Kubernetes](#uninstall-kubernetes)

# Introduction

Hereafter we describe the instructions to install [K3s Lightweight Kubernetes](https://rancher.com/docs/k3s/latest/en/)
on an onpremise cluster.

> **_NOTE:_** A developer or tester can deploy a small cluster in AWS using these [Terraform source codes](../../utils/create-cluster). This is useful for the development and testing only!

# Install Docker

To install docker on each node of the cluster, you can follow the instructions
presented [here](https://docs.docker.com/engine/install/) for each distribution.

# Install Kubernetes 

## On master node 

Use the following procedure to install and configure Kubernetes on the master node:

* If you are on the master, execute:

```bash
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--tls-san <master-public-address-ip> --cluster-cidr 192.168.0.0/16" sh -s - --write-kubeconfig-mode 644
mkdir -p ~/.kube
cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
```

* If not, you can execute the following remote command:

```bash
ssh -i <public-ssh-key-path> -o "StrictHostKeyChecking no" <user>@<master-public-address-ip> 'curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--tls-san <master-public-address-ip> --cluster-cidr 192.168.0.0/16" sh -s - --write-kubeconfig-mode 644 ; mkdir -p ~/.kube ; cp /etc/rancher/k3s/k3s.yaml ~/.kube/config'
```

where :

* `<public-ssh-key-path>` is the path of the public key to SSH the cluster instances.
* `<user>` the user on the master node
* `<master-public-address-ip>` is the public IP of the master node.

## On worker nodes 

Use the following command to configure the workers as follows:

* If you are on a worker, execute:

```bash
# retrieve the Kubernetes `node-token` from the master node
token=$(ssh -i <public-ssh-key-path> <user>@<master-public-address-ip> 'sudo cat /var/lib/rancher/k3s/server/node-token')
# configure Kubernetes
curl -sfL https://get.k3s.io | K3S_URL=https://<master-public-address-ip>:6443 K3S_TOKEN=$token sh -
```

* If not, execute the following remote command on all workers:

```bash
# retrieve the Kubernetes `node-token` from the master node
token=$(ssh -i <public-ssh-key-path> <user>@<master-public-address-IP> 'sudo cat /var/lib/rancher/k3s/server/node-token')
# configure Kubernetes
for ip in <list-public-ip-addresses-of-workers>; do ssh -i <public-ssh-key-path> -o "StrictHostKeyChecking no" <user>@$ip "curl -sfL https://get.k3s.io | K3S_URL=https://<master-public-address-ip>:6443 K3S_TOKEN=$token sh -"; done
```

where:

* `<public-ssh-key-path>` is the path of the public key to SSH the cluster instances.
* `<user>` the user on the master node.
* `<master-public-address-ip>` is the public IP of the master node.
* `<list-public-ip-addresses-of-workers>` is the list of public IP addresses of worker nodes.

# Accessing the cluster from outside 

Copy `/etc/rancher/k3s/k3s.yaml` from the master on your machine located outside the cluster as `~/.kube/config`. Then
replace `localhost` or the private address IP with the public with the IP the K3s server (master node). kubectl can now
manage your K3s cluster from your local machine.

# Uninstall Kubernetes 

On each node of the cluster, execute the command:

```bash
/usr/local/bin/k3s-uninstall.sh
```
