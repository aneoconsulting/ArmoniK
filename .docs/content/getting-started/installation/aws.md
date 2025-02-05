# ArmoniK on AWS

## AWS Setup 🚀

This guide will help you install and configure the AWS CLI on your system and set up your AWS environment for use.

### 1. Installation & Configuration

Follow the official AWS CLI install guide [here](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html).

For Linux-based systems, you can use the following commands:

```bash
curl "https://awscli.amazonaws.com/aws-cli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
```

Ensure the AWS CLI is installed correctly by checking its version:

```bash
aws --version
```

### 2. Configure AWS CLI

Once installed, you need to configure the AWS CLI with your credentials:

```bash
aws configure
```

During configuration:
- Enter your **Access Key ID** and **Secret Access Key** (provided by AWS).
- Choose a default region, e.g., *eu-west-3* (optional but recommended).
- Specify the default output format (e.g., *json*, *table*, or *text*).
- The advised output format is *json*.

To be able to interact with the AWS CLI, you need to set up your AWS Single Sign-On (SSO) credentials. This is realized by running the following command:

```bash
aws sso login
```

Each time you want to deploy ArmoniK on AWS, you need to run this command to authenticate.

You should click on the URL provided in the output to open the SSO authorization page in a browser.

### Step 1: AWS Authentication Setup

To be able to interact with the AWS CLI, you need to set up your AWS Single Sign-On (SSO) credentials. This is realized by running the following command:

```bash
aws sso login
```

Each time you want to deploy ArmoniK on AWS, you need to run this command to authenticate.

You should click on the URL provided in the output to open the SSO authorization page in a browser. It will open the SSO authorization page in your default browser. After logging in, you’ll be prompted to grant permissions.

### Step 2: Verify Login

- Once authorized, the CLI will confirm successful login.
- Your authorization page should look similar to this:

![AWS CLI Access](https://armonik-public-images.s3.eu-west-3.amazonaws.com/deployment-doc/aws-cli-access.png)

## AWS all in one deployment

Deploying on AWS is similar to deploying on localhost but with the necessity to deploy an S3 bucket first.

### Generate S3 bucket key

Execute the following command to generate a prefix key:

```bash
make bootstrap-deploy PREFIX=<PREFIX_KEY>
```

To deploy, simply execute the following command:

```bash
make deploy PREFIX=<PREFIX_KEY>
```

Note : after the deployment, you can retrieve the prefix key in the prefix file: `<PATH_TO_AWS_FOLDER>/generated/.prefix`

To destroy the deployment, execute the following command:

```bash
make destroy PREFIX=<PREFIX_KEY>
```

To destroy the AWS prefix key, execute the following command:

```bash
make bootstrap-destroy PREFIX=<PREFIX_KEY>
```

### Accessing Kubernetes cluster

To access your Kubernetes cluster, execute the following command after entering your settings in the 3 angle brackets:

```bash
aws --profile <AWS_PROFILE> eks update-kubeconfig --region <AWS_REGION> --name <NAME_AWS_EKS>
```

or simply enter the following command:

```bash
export KUBECONFIG=<PATH_TO_AWS_FOLDER>/generated/kubeconfig
```

### Configuration

All parameters are contained in [`parameters.tfvars`](../../../../infrastructure/quick-deploy/aws/parameters.tfvars)



```{note}

By default, all the cloud services are set to launch. To see what kind of parameters are available, read [`variables.tf`](../../../../infrastructure/quick-deploy/aws/variables.tf)

```

You can specify a custom parameter file. When executing the `make` command, you may use the `PARAMETERS_FILE` option to set the path to your file.

```bash
make PARAMETERS_FILE=my-custom-parameters.tfvars
```

## AWS deployment using k3s

### Introduction

This project presents the creation of a small cluster on AWS. The cluster will be composed of a master node and three
worker nodes.

The files to achieve this deployment are available [in the repository](https://github.com/aneoconsulting/ArmoniK/tree/main/infrastructure/docs/kubernetes/cluster/k3s-cluster)

We mount a NFS server on the master node too, from which workers will upload .dll.



```{note}

You muse have an AWS account to use these sources to create a cluster.

```

### AWS credentials

You must create and provide
your [AWS programmatic access keys](https://docs.aws.amazon.com/general/latest/gr/aws-sec-cred-types.html#access-keys-and-secret-access-keys)
in your dev/test environment:

```bash [shell]
mkdir -p ~/.aws
cat <<EOF | tee ~/.aws/credentials
[default]
aws_access_key_id = <ACCESS_KEY_ID>
aws_secret_access_key = <SECRET_ACCESS_KEY>
EOF
```

### Generate a SSH key pair

Use the following procedure to generate a SSH key pair and save it in `~/.ssh`:

```bash [shell]
ssh-keygen -b 4096 -t rsa -f ~/.ssh/cluster-key
```

The generated SSH key pair `cluster-key` will be used to ssh the instances of the cluster.

### Deploy a cluster

We will create a cluster on AWS composed of four ec2 instances:

* a master node
* three worker nodes

In [parameters.tfvars](../../../../infrastructure/docs/kubernetes/cluster/k3s-cluster/parameters.tfvars):

* set the value of the parameter `ssh_key` with the content of the public SSH key `~/.ssh/cluster-key.pub` and the path
  to the private SSH key, for example:

  ```bash [shell]
  ssh_key = {
    private_key_path = "~/.ssh/cluster-key"
    public_key       = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQD3F6tyPEFEzV0LX3X8BsXdMsQz1x2cEikKDEY0aIj41qgxMCP/iteneqXSIFZBp5vizPvaoIR3Um9xK7PGoW8giupGn+EPuxIA4cDM4vzOqOkiMPhz5XK0whEjkVzTo4+S0puvDZuwIsdiW9mxhJc7tgBNL0cYlWSYVkz4G/fslNfRPW5mYAM49f4fhtxPb5ok4Q2Lg9dPKVHO/Bgeu5woMc7RY0p1ej6D4CKFE6lymSDJpW0YHX/wqE9+cfEauh7xZcG0q9t2ta6F6fmX0agvpFyZo8aFbXeUBr7osSCJNgvavWbM/06niWrOvYX2xwWdhXmXSrbX8ZbabVohBK41 email@example.com"
  }
  ```

* set the ID of an existing VPC and its subnet:

  ```bash [shell]
  vpc_id    = "<VPC_ID>"
  subnet_id = "<SUBNET_ID>"
  ```

To deploy the cluster execute the command:

```bash [shell]
make all
```

The outputs display the public IP of each instance, like:

```bash [shell]
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

### Prerequisites

You must open the following inbound ports:

| IPv4 | Custom TCP   | TCP          | 30000 - 32767 | 0.0.0.0/0      | ArmoniK services |
| ---- | ------------ | ------------ | ------------- | -------------- | ---------------- |
| IPv4 | IP-in-IP (4) | IP-in-IP (4) | All           | 192.168.0.0/16 | ArmoniK services |

### Accessing the cluster from outside

Copy `/etc/rancher/k3s/k3s.yaml` from the master on your machine located outside the cluster as `~/.kube/config`. Then
replace `localhost` or the private address IP with the public with the IP the K3s server (master node). kubectl can now
manage your K3s cluster from your local machine.

### Destroy the cluster

To delete all resources of the cluster created on AWS, execute the command:

```bash [shell]
make destroy
```
## AWS deployment using kubeadm

### Introduction

This project presents the creation of a small cluster on AWS. The cluster will be composed of a master node and three
worker nodes.

The files to achieve this deployment are available [here](https://github.com/aneoconsulting/ArmoniK/tree/main/infrastructure/docs/kubernetes/cluster/kubeadm-cluster)

We mount a NFS server on the master node too, from which workers will upload .dll.



```{note}

You muse have an AWS account to use these sources to create a cluster.

```

### AWS credentials

You must create and provide
your [AWS programmatic access keys](https://docs.aws.amazon.com/general/latest/gr/aws-sec-cred-types.html#access-keys-and-secret-access-keys)
in your dev/test environment:

```bash [shell]
mkdir -p ~/.aws
cat <<EOF | tee ~/.aws/credentials
[default]
aws_access_key_id = <ACCESS_KEY_ID>
aws_secret_access_key = <SECRET_ACCESS_KEY>
EOF
```

### Generate a SSH key pair

Use the following procedure to generate a SSH key pair and save it in `~/.ssh`:

```bash [shell]
ssh-keygen -b 4096 -t rsa -f ~/.ssh/cluster-key
```

The generated SSH key pair `cluster-key` will be used to ssh the instances of the cluster.

### Deploy a cluster

We will create a cluster on AWS composed of four ec2 instances:

* a master node
* three worker nodes

In [parameters.tfvars](https://github.com/aneoconsulting/ArmoniK/blob/main/infrastructure/docs/kubernetes/cluster/kubeadm-cluster/parameters.tfvars):

* set the value of the parameter `ssh_key` with the content of the public SSH key `~/.ssh/cluster-key.pub` and the path
  to the private SSH key, for example:

  ```bash [shell]
  ssh_key = {
    private_key_path = "~/.ssh/cluster-key"
    public_key       = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQD3F6tyPEFEzV0LX3X8BsXdMsQz1x2cEikKDEY0aIj41qgxMCP/iteneqXSIFZBp5vizPvaoIR3Um9xK7PGoW8giupGn+EPuxIA4cDM4vzOqOkiMPhz5XK0whEjkVzTo4+S0puvDZuwIsdiW9mxhJc7tgBNL0cYlWSYVkz4G/fslNfRPW5mYAM49f4fhtxPb5ok4Q2Lg9dPKVHO/Bgeu5woMc7RY0p1ej6D4CKFE6lymSDJpW0YHX/wqE9+cfEauh7xZcG0q9t2ta6F6fmX0agvpFyZo8aFbXeUBr7osSCJNgvavWbM/06niWrOvYX2xwWdhXmXSrbX8ZbabVohBK41 email@example.com"
  }
  ```

* set the ID of an existing VPC and its subnet:

  ```bash [shell]
  vpc_id    = "<VPC_ID>"
  subnet_id = "<SUBNET_ID>"
  ```

To deploy the cluster execute the command:

```bash [shell]
make all
```

The outputs display the public IP of each instance, like:

```bash [shell]
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

### Prerequisites

You must open the following inbound ports:

| IPv4 | Custom TCP   | TCP          | 30000 - 32767 | 0.0.0.0/0      | ArmoniK services |
| ---- | ------------ | ------------ | ------------- | -------------- | ---------------- |
| IPv4 | IP-in-IP (4) | IP-in-IP (4) | All           | 192.168.0.0/16 | ArmoniK services |

### Accessing the cluster from outside

Copy `/etc/kubernetes/admin.conf` from the master on your machine located outside the cluster as `~/.kube/config`. Then
replace `localhost` or the private address IP with the public IP of the Kubeadm server (master node). kubectl can now
manage your Kubeadm cluster from your local machine.

### Destroy the cluster

To delete all resources of the cluster created on AWS, execute the command:

```bash [shell]
make destroy
```