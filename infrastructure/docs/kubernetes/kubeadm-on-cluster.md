# Table of contents

1. [Introduction](#introduction)
2. [Install Docker](#install-docker)
3. [Install Kubernetes](#install-kubernetes)
    1. [On master node](#on-master-node)
    2. [On worker nodes](#on-worker-nodes)
4. [Accessing the cluster from outside](#accessing-the-cluster-from-outside)

# Introduction

Hereafter we describe the instructions to install `Kubeadm` on an onpremise cluster.

> **_NOTE:_** A developer or tester can deploy a small cluster in AWS using these [Terraform source codes](../../utils/create-cluster). This is useful for the development and testing only!

# Install Docker

To install docker on each node of the cluster, you can follow the instructions
presented [here](https://docs.docker.com/engine/install/) for each distribution.

# Install Kubernetes

Execute the following instruction **on all nodes**:

1. As a requirement for your Linux Node's iptables to correctly see bridged traffic, you should ensure
   `net.bridge.bridge-nf-call-iptables` is set to `1` in your `sysctl` config, e.g:

```bash
sudo modprobe br_netfilter
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
br_netfilter
EOF

cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sudo sysctl --system
```

2. You will install these packages on all of your machines:
    * `kubeadm`: the command to bootstrap the cluster.
    * `kubelet`: the component that runs on all of the machines in your cluster and does things like starting pods and
      containers.
    * `kubectl`: the command line util to talk to your cluster.

```bash
cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-\$basearch
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
exclude=kubelet kubeadm kubectl
EOF

# Set SELinux in permissive mode (effectively disabling it)
sudo setenforce 0
sudo sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config

sudo yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes

sudo systemctl enable --now kubelet
```

3. Configure Docker daemon to use systemd:

```bash
sudo mkdir -p /etc/docker
cat <<EOF | sudo tee /etc/docker/daemon.json
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2"
}
EOF

sudo systemctl enable docker
sudo systemctl daemon-reload
sudo systemctl restart docker
```

## On master node

1. Initialize kubeadm on master node:

```bash
sudo kubeadm init --apiserver-cert-extra-sans=<master-public-address-ip> --pod-network-cidr=192.168.0.0/16

mkdir -p $HOME/.kube
# Copy conf file to .kube directory for current user
sudo cp /etc/kubernetes/admin.conf $HOME/.kube/config
# Change ownership of file to current user and group
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

where:

* `<master-public-address-ip>` is the public IP of the master node.

**warning:** the end of the output of this command display the join command to execute on worker nodes.

2. Install the Calico:

```bash
#curl -s https://docs.projectcalico.org/manifests/calico.yaml > calico.yaml
#POD_CIDR="172.31.0.0/16" sed -i -e "s?192.168.0.0/16?$POD_CIDR?g" calico.yaml
#kubectl apply -f calico.yaml
kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml
```

## On worker nodes

Run the join command on worker nodes:

```bash
sudo kubeadm join <master-public-address-ip>:6443 --token <token-value> --discovery-token-ca-cert-hash <token-hash>
```

where:

* `<master-public-address-ip>` is the public IP of the master node.
* `<token-value>` and `<token-hash>` are, respectively, the value and the hash of the token generated after the
  installation of Kubeadm on the master node.

# Accessing the cluster from outside

Copy `/etc/kubernetes/admin.conf` from the master on your machine located outside the cluster as `~/.kube/config`. Then
replace `localhost` or the private address IP with the public IP of the Kubeadm server (master node). kubectl can now
manage your Kubeadm cluster from your local machine.
