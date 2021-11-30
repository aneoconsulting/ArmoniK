# Table of contents
1. [Introduction](#introduction)
2. [Getting started](#getteing-started)
   1. [Software prerequisites](#software-prerequisites)
   2. [Install Kubernetes](#install-kubernetes)
3. [Create Kubernetes secrets](#create-kubernetes-secrets)
   1. [Object storage secret](#object-storage-secret)

# Introduction <a name="introduction"></a>
Hereafter, we describe the steps to deploy ArmoniK on local machine. All components of ArmoniK and services used with 
ArmoniK (example: different storage) are deployed as services in the Kubernetes cluster.

# Getting started <a name="getting-started"></a>
## Software prerequisites <a name="software-prerequisites"></a>
The following resources should be installed upon you local machine :

* docker version > 1.19

* kubectl version > 1.19

* [Terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli) version > 1.0.0

* [helm](https://helm.sh/docs/intro/install/) version > 3

## Install Kubernetes <a name="install-kubernetes"></a>
Instructions to install Kubernetes on local Linux machine.

You can use [K3s Lightweight Kubernetes](https://rancher.com/docs/k3s/latest/en/) on Linux OS.

Install K3s as follows:

```bash
  curl -sfL https://get.k3s.io | sh -
```

If you want use host's Docker rather than containerd use `--docker` option:

```bash
  curl -sfL https://get.k3s.io | sh -s - --docker
```

Then initialize the configuration file of Kubernetes:

```bash
  sudo chmod 755 /etc/rancher/k3s/k3s.yaml
  mkdir -p ~/.kube
  cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
```

To uninstall K3s, use the following command:

```bash
  /usr/local/bin/k3s-uninstall.sh
```

# Create Kubernetes secrets <a name="create-kubernetes-secrets"></a>
## Object storage secret <a name="object-storage-secret"></a>
In this project, we use Redis as object storage for Armonik. Redis uses SSL/TLS support using certificates. In order to 
support TLS, Redis is configured with a X.509 certificate (`cert.crt`) and a private key (`cert.key`). In addition, it 
is necessary to specify a CA certificate bundle file (`ca.crt`) or path to be used as a trusted root when validating 
certificates. A SSL certificate of type `PFX` is also used (`certificate.pfx`).

Execute the following command to create the object storage secret in Kubernetes based on the certificates created and
saved in the directory `$ARMONIK_OBJECT_STORAGE_CERTIFICATES_DIRECTORY`. In this project, we have certificates for test
in [certificates](./certificates) directory:
1. Set an environment variable to the path of the directory containing the certificates:

   ```bash
      export ARMONIK_OBJECT_STORAGE_CERTIFICATES_DIRECTORY=<path-to-directory-of-certificates>
   ```
2. Create a Kubernetes secret for the ArmoniK object storage:

   ```bash
      kubectl create secret generic object-storage-secret \
              --from-file=$ARMONIK_OBJECT_STORAGE_CERTIFICATES_DIRECTORY/cert.crt \
              --from-file=$ARMONIK_OBJECT_STORAGE_CERTIFICATES_DIRECTORY/cert.key \
              --from-file=$ARMONIK_OBJECT_STORAGE_CERTIFICATES_DIRECTORY/ca.crt \
              --from-file=$ARMONIK_OBJECT_STORAGE_CERTIFICATES_DIRECTORY/certificate.pfx
   ```