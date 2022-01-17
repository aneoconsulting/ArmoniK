# Table of contents

1. [Introduction](#introduction)
2. [AWS credentials](#aws-credentials)
3. [Generate a SSH key pair](#generate-a-ssh-key-pair)
4. [Deploy a cluster](#deploy-a-cluster)
    1. [On master node](#on-master-node)
    2. [On worker nodes](#on-worker-nodes)
5. [Accessing the cluster from outside](#accessing-the-cluster-from-outside)
6. [Destroy the cluster](#destroy-the-cluster)

# Introduction

This project presents the creation of a small cluster on AWS. The cluster will be composed of a master node and three
worker nodes.

We mount a NFS server on the master node too, from which workers will upload .dll.

> **_NOTE:_** You must have an AWS account to use these sources to create a cluster.

# AWS credentials

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

# Generate a SSH key pair

Use the following procedure to generate a SSH key pair and save it in `~/.ssh`:

```bash
ssh-keygen -b 4096 -t rsa -f ~/.ssh/cluster-key
```

The generated SSH key pair `cluster-key` will be used to ssh the instances of the cluster.

# Deploy a cluster

We will create a cluster on AWS composed of four ec2 instances:

* a master node
* three worker nodes

In [parameters.tfvars](parameters.tfvars), set the value of the parameter `ssh_key` with the content of the public SSH
key `~/.ssh/cluster-key.pub` and the path to the private SSH key, for example:

```bash
ssh_key = {
  private_key_path = "~/.ssh/cluster-key"
  public_key       = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQD3F6tyPEFEzV0LX3X8BsXdMsQz1x2cEikKDEY0aIj41qgxMCP/iteneqXSIFZBp5vizPvaoIR3Um9xK7PGoW8giupGn+EPuxIA4cDM4vzOqOkiMPhz5XK0whEjkVzTo4+S0puvDZuwIsdiW9mxhJc7tgBNL0cYlWSYVkz4G/fslNfRPW5mYAM49f4fhtxPb5ok4Q2Lg9dPKVHO/Bgeu5woMc7RY0p1ej6D4CKFE6lymSDJpW0YHX/wqE9+cfEauh7xZcG0q9t2ta6F6fmX0agvpFyZo8aFbXeUBr7osSCJNgvavWbM/06niWrOvYX2xwWdhXmXSrbX8ZbabVohBK41 email@example.com"
}
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
  }
]
```

## On master node

1. Initialize kubeadm on master node:

```bash
ssh -i ~/.ssh/cluster-key -o "StrictHostKeyChecking no" ec2-user@<master-public-address-ip> 'sudo kubeadm init --apiserver-cert-extra-sans=<master-public-address-ip> --pod-network-cidr=192.168.0.0/16 ; mkdir -p $HOME/.kube ; sudo cp /etc/kubernetes/admin.conf $HOME/.kube/config ; sudo chown $(id -u):$(id -g) $HOME/.kube/config'
```

**warning:** the end of the output of this command display the join command to execute on worker nodes.

2. Install the network plugin Calico:

```bash
ssh -i ~/.ssh/cluster-key -o "StrictHostKeyChecking no" ec2-user@<master-public-address-ip> "curl -s https://docs.projectcalico.org/manifests/calico.yaml > calico.yaml ; sed -i -e 's?# - name: CALICO_IPV4POOL_CIDR?- name: CALICO_IPV4POOL_CIDR?g' calico.yaml ; sed -i -e 's?#   value: \"192.168.0.0/16\"?  value: \"192.168.0.0/16\"?g' calico.yaml ; kubectl apply -f calico.yaml"
```

where:

* `<master-public-address-ip>` is the public IP of the master node.

## On worker nodes

Run the join command on worker nodes:

```bash
token=$(ssh -i ~/.ssh/cluster-key -o "StrictHostKeyChecking no" ec2-user@<master-public-address-ip> 'kubeadm token list' | sed 1d | awk '{print $1}') ; token_hash=$(ssh -i ~/.ssh/cluster-key -o "StrictHostKeyChecking no" ec2-user@<master-public-address-ip> 'openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt | openssl rsa -pubin -outform der 2>/dev/null | openssl dgst -sha256 -hex' | sed 's/^.* //') ; for ip in <list-public-ip-addresses-of-workers>; do ssh -i ~/.ssh/cluster-key -o "StrictHostKeyChecking no" ec2-user@$ip "sudo kubeadm join <master-public-address-ip>:6443 --token $token --discovery-token-ca-cert-hash $token_hash"; done
```

where:

* `<master-public-address-ip>` is the public IP of the master node.
* `<list-public-ip-addresses-of-workers>` is the list of public IP addresses of worker nodes.

# Accessing the cluster from outside

Copy `/etc/kubernetes/admin.conf` from the master on your machine located outside the cluster as `~/.kube/config`. Then
replace `localhost` or the private address IP with the public IP of the Kubeadm server (master node). kubectl can now
manage your Kubeadm cluster from your local machine.

# Destroy the cluster

To delete all resources of the cluster created on AWS, execute the command:

```bash
make destroy
```