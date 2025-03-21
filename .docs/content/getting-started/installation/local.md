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



```{note}

If you plan to use **ArmoniK for production purposes**, you must install [Kubernetes](#kubernetes) instead of K3s.

```

ArmoniK uses K3s as it uses Kubernetes but for development environment.



```{note}

What is K3s? K3s is a lightweight Kubernetes distribution built for production workloads in unattended, resource-constrained, remote locations or inside IoT appliances. [Read more](https://k3s.io/).

```

### Simplified installer


You can easily install all of them using the [ArmoniK prerequisites installer](https://github.com/aneoconsulting/ArmoniK/blob/main/infrastructure/utils/scripts/installation/prerequisites-installer.sh) from the root repository.

```bash [shell]
./infrastructure/utils/scripts/installation/prerequisites-installer.sh
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
chmod +x ./infrastructure/utils/scripts/installation/prerequisites-installer.sh
# Add execution permissions to every script in the prerequisites directory
chmod +x ./infrastructure/utils/scripts/installation/prerequisites/*

```


## Install ArmoniK


Now, you are ready to deploy ArmoniK on Kubernetes ! See [Kubernetes deployment](./kubernetes.md) for how to do so !
