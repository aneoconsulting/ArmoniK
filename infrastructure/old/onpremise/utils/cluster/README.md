# Table of contents

1. [Introduction](#introduction)
2. [AWS credentials](#aws-credentials)
3. [Generate an SSH key pair](#generate-an-ssh-key-pair)
4. [Deploy a cluster](#deploy-a-cluster)
5. [Install and configure Kubernetes](#install-and-configure-kubernetes)
6. [Accessing the Cluster from outside](#accessing-the-cluster-from-outside)
7. [Destroy the cluster](#destroy-the-cluster)

# Introduction <a name="introduction"></a>

In this project, we present an example of the deployment of small cluster on AWS and the installation and configuration
of a Kubernetes on this cluster.

We mount a NFS server on the master node too, from which pods will upload dll.

> **_NOTE:_** You must have an AWS account to use these sources to deploy a cluster.

# AWS credentials <a name="aws-credentials"></a>

You must create and provide
your [AWS programmatic access keys](https://docs.aws.amazon.com/general/latest/gr/aws-sec-cred-types.html#access-keys-and-secret-access-keys)
in your dev/test environment:

```bash
mkdir -p ~/.aws
cat <<EOF | tee ~/.aws/credentials
[default]
aws_access_key_id = <ACCESS_KEY_ID>
aws_secret_access_key = <SECRET_ACCESS_KEY>
EOF
```

# Generate an SSH key pair <a name="generate-an-ssh-key-pair"></a>

Use the following procedure to generate an SSH key pair and save it in `~/.ssh`:

```bash
ssh-keygen -b 4096 -t rsa -f ~/.ssh/k3s-key
```

The generated SSH key pair `k3s-key` will be used to ssh the instances of the cluster.

# Deploy a cluster <a name="deploy-a-cluster"></a>

We will create a cluster on AWS composed of four ec2 instances:

* a master node of Kubernetes
* three worker nodes

In [parameters.tfvars](parameters.tfvars), set the value of the parameter `ssh_key` with the public SSH
key `~/.ssh/k3s-key.pub`, for example:

```bash
ssh_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQD3F6tyPEFEzV0LX3X8BsXdMsQz1x2cEikKDEY0aIj41qgxMCP/iteneqXSIFZBp5vizPvaoIR3Um9xK7PGoW8giupGn+EPuxIA4cDM4vzOqOkiMPhz5XK0whEjkVzTo4+S0puvDZuwIsdiW9mxhJc7tgBNL0cYlWSYVkz4G/fslNfRPW5mYAM49f4fhtxPb5ok4Q2Lg9dPKVHO/Bgeu5woMc7RY0p1ej6D4CKFE6lymSDJpW0YHX/wqE9+cfEauh7xZcG0q9t2ta6F6fmX0agvpFyZo8aFbXeUBr7osSCJNgvavWbM/06niWrOvYX2xwWdhXmXSrbX8ZbabVohBK41 email@example.com"
```

To deploy the cluster execute the command:

```bash
make all
```

The outputs display the public IP of each instance, like:

```bash
master_public_ip = {
  "ip" = "54.185.23.147"
  "name" = "i-0168c936872babdf2"
}
worker_public_ip = [
  {
    "ip" = "54.184.45.26"
    "name" = "i-06b8aeab6cb62750a"
  },
  {
    "ip" = "35.87.249.26"
    "name" = "i-0e4c32d39bfcf8aac"
  },
  {
    "ip" = "54.244.169.65"
    "name" = "i-0c691f1d971e62150"
  },
]
```

# Install and configure Kubernetes <a name="install-and-configure-kubernetes"></a>

Hereafter, we will use [K3s Lightweight Kubernetes](https://rancher.com/docs/k3s/latest/en/).

## On master node

Use the following procedure to install and configure Kubernetes on the master node:

```bash
ssh -i ~/.ssh/k3s-key.pub -o "StrictHostKeyChecking no" ec2-user@54.185.23.147 'curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--tls-san 54.185.23.147" sh -'
```

where `54.185.23.147` is the public IP of the master node.

Then execute the following command to configure Kubernets CLI:

```bash
ssh -i ~/.ssh/k3s-key.pub ec2-user@54.185.23.147 'sudo chmod 644 /etc/rancher/k3s/k3s.yaml ; mkdir -p ~/.kube ; cp /etc/rancher/k3s/k3s.yaml ~/.kube/config'
```

## On workers

Use the following command to retrieve the Kubernetes `node-token` from the master node:

```bash
token=$(ssh ec2-user@54.185.23.147 'sudo cat /var/lib/rancher/k3s/server/node-token')
```

then configure the workers as follows:

```bash
for ip in 54.184.45.26 35.87.249.26 54.244.169.65; do ssh -i ~/.ssh/k3s-key.pub -o "StrictHostKeyChecking no" ec2-user@$ip "curl -sfL https://get.k3s.io | K3S_URL=https://54.185.23.147:6443 K3S_TOKEN=$token sh -"; done
```

where `54.184.45.26`, `35.87.249.26` and `54.244.169.65` are the public IP of the workers.

# Accessing the Cluster from outside <a name="accessing-the-cluster-from-outside"></a>

Copy `/etc/rancher/k3s/k3s.yaml` from the master on your machine located outside the cluster as `~/.kube/config`. Then
replace `localhost` with the IP the K3s server (master node). kubectl can now manage your K3s cluster from your local
machine.

# Destroy the cluster <a name="Destroy the cluster"></a>

To delete all resources of the cluster created on AWS, execute the command:

```bash
make destroy
```