# Software prerequisites

The following software should be installed upon your machine regardless of the environment of the deployment. This
machine can host Kubernetes for dev/test environment, or the login machine to deploy and manage ArmoniK on a distant
Kubernetes cluster. Hereafter, we give instructions to install the prerequisites on Debian/Ubuntu Linux OS.

***Warning:*** If you have a **Windows machine** you must first
install [WSL 2 and SystemD](kubernetes/onpremise/localhost/wsl2.md) before installing the software prerequisites.

## Dependencies

First you must install the following packages:

```bash
sudo apt install apt-transport-https ca-certificates curl gnupg lsb-release jq
```

## AWS CLI

[AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-welcome.html) installation instructions:

```bash
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
```

## Docker

The procedure to install [Docker](https://docs.docker.com/engine/install/ubuntu/):

```bash
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io
```

## Helm

[Helm](https://helm.sh/) is a tool for managing Charts. Charts are packages of pre-configured Kubernetes resources:

```bash
curl https://baltocdn.com/helm/signing.asc | sudo apt-key add -
sudo apt install apt-transport-https --yes
echo "deb https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
sudo apt update
sudo apt install -y helm
```

## Kubectl

The Kubernetes CLI (kubectl), allows you to run commands against Kubernetes clusters. You must use
a [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/) version that is within one minor version
difference of your cluster. For example, a v1.23 client can communicate with v1.22, v1.23, and v1.24 control planes.
Using the latest compatible version of kubectl helps avoid unforeseen issues.

```bash
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
curl -LO "https://dl.k8s.io/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl.sha256"
echo "$(<kubectl.sha256) kubectl" | sha256sum --check
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
kubectl version --client
```

## Python

You must install `python > 3.7` and `pip3`:

```bash
sudo apt install -y software-properties-common
sudo add-apt-repository ppa:deadsnakes/ppa
sudo apt update
sudo apt install -y python3.7
sudo apt install -y python3-pip
```

## Terraform

The procedure to install [Terraform](https://www.terraform.io/docs/cli/install/apt.html):

```bash
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
sudo apt-add-repository "deb [arch=$(dpkg --print-architecture)] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
sudo apt install terraform
```