# Local deployment

If you want to deploy ArmoniK on your machine, this section is for you.



```{note}

This deployment is for development purposes.

```

## WSL installation on Windows


```{warning}

Currently, ArmoniK is only available on Linux. But you can use [WSL2](https://learn.microsoft.com/fr-fr/windows/wsl/install) with [systemd](https://learn.microsoft.com/fr-fr/windows/wsl/systemd)to install ArmoniK on Windows.

This installation method is not recommended for production environments.

```

ArmoniK can be installed on Windows 10 and 11 using the [Windows Subsystem for Linux](https://learn.microsoft.com/en-us/windows/wsl/install).



```{note}

You can read more about WSL2 on the [Microsoft documentation](https://learn.microsoft.com/en-us/windows/wsl/compare-versions).

```

## Prerequisites


### Kubernetes



```{danger}

If you plan to install **ArmoniK for development purposes**, you must install [K3s](#k3s) instead of Kubernetes.

```

ArmoniK uses Kubernetes to orchestrate containers. You must have Kubernetes installed on your machine. You can follow the [official documentation](https://kubernetes.io/releases/download/) to install Kubernetes on your machine.



```{note}

What is Kubernetes? Kubernetes, also known as K8s, is an open-source system for automating deployment, scaling, and management of containerized applications. It groups containers that make up an application into logical units for easy management and discovery. [Read more](https://en.wikipedia.org/wiki/Kubernetes).

```

### K3s

ArmoniK uses K3s as it uses Kubernetes but for development environment.

```{note}

What is K3s? K3s is a lightweight Kubernetes distribution built for production workloads in unattended, resource-constrained, remote locations or inside IoT appliances. [Read more](https://k3s.io/).

```


#### K3S Installation

If you already have a K3s installation, start by [uninstalling it](https://docs.k3s.io/installation/uninstall) properly.


#### Step 1: Run the installation script

##### Option A: Use custom installation script (Recommended)
Use our installation script available here: [tools/installation/prerequisites/install-k3s.sh](https://github.com/aneoconsulting/ArmoniK/blob/main/tools/installation/prerequisites/install-k3s.sh)

##### Option B: Use the official installation script
You can also use the official installation script to [install K3s](https://docs.k3s.io/quick-start)


#### Step 2: Verify the installation

Ensure K3s is running and kubectl can access the cluster.

```bash
sudo systemctl status k3s
kubectl get nodes
```


##### Troubleshooting: Kube Configuration



> **Note**: If your kube configuration was not created during installation or if you get permission errors, you can manually configure it:
>
> - Create the kube directory
> - Copy your kube config to a new config file
> - Adjust permissions
>
> ```bash
> mkdir -p ~/.kube
> sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
> sudo chown $(id -u):$(id -g) ~/.kube/config
> ```



### Simplified installer


You can easily install all of them using the [ArmoniK prerequisites installer](https://github.com/aneoconsulting/ArmoniK/blob/main/tools/installation/prerequisites-installer.sh) from the root repository.

```bash [shell]
./tools/installation/prerequisites-installer.sh
```


```{note}

Please, read the script before running it and make sure to have Docker Desktop disabled if you are on Windows.

```


```{warning}

We do not recommend you to manually install the pre-requisites for compatibility reasons. If you want to install them manually, please follow the prerequisites installer script.

```


```{warning}

You could encounter some issues with the execution of the prerequisites installer script. Please verify you've right permissions on the script. If not, you can use `chmod +x <file|directory/*>` to add the execution permissions.


```sh

# Add execution permissions to the prerequisites installer script
chmod +x ./tools/installation/prerequisites-installer.sh
# Add execution permissions to every script in the prerequisites directory
chmod +x ./tools/installation/prerequisites/*

```


## Install ArmoniK


Now, you are ready to deploy ArmoniK on Kubernetes ! See [Kubernetes deployment](./kubernetes.md) for how to do so !
