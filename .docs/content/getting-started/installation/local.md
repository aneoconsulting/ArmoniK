# Local all in one deployment

If you want to deploy ArmoniK with all the cloud services, this section is for you.

::alert{type="info"}
This deployment is for development purposes.
::
## Installation

### Installation on Windows

::alert{type="warning"}
Currently, ArmoniK is only available on Linux. But you can use [WSL2](https://learn.microsoft.com/fr-fr/windows/wsl/install) with [systemd](https://learn.microsoft.com/fr-fr/windows/wsl/systemd)to install ArmoniK on Windows.
This installation method is not recommended for production environments.
::

ArmoniK can be installed on Windows 10 and 11 using the [Windows Subsystem for Linux](https://learn.microsoft.com/en-us/windows/wsl/install).

::alert{type="info"}
You can read more about WSL2 on the [Microsoft documentation](https://learn.microsoft.com/en-us/windows/wsl/compare-versions).
::

### Install ArmoniK

::alert{type="warning"}
Be careful, you must enable `systemd` support before installing ArmoniK.
::

First, clone the ArmoniK repository (inside your home directory from WSL2 Ubuntu distribution):

```bash [shell]
git clone https://github.com/aneoconsulting/ArmoniK.git
```

## Deploy

To launch the deployment, go to the [`infrastructure/quick-deploy/localhost`](https://github.com/aneoconsulting/ArmoniK/tree/main/infrastructure/quick-deploy/localhost) directory:

If you want to deploy on AWS, go to the dedicated section on [`AWS`](https://github.com/aneoconsulting/ArmoniK/tree/main/infrastructure/quick-deploy/aws)

Execute the following command:

```bash
make
```

or

```bash
make deploy
```

### Configuration

All parameters are contained in [`parameters.tfvars`](https://github.com/aneoconsulting/ArmoniK/blob/main/infrastructure/quick-deploy/localhost/parameters.tfvars)

::alert{type="info"}
By default, all the cloud services are set to launch. To see what kind of parameters are available, read [`variables.tf`](https://github.com/aneoconsulting/ArmoniK/blob/main/infrastructure/quick-deploy/localhost/variables.tf)
::

You can specify a custom parameter file. When executing the `make` command, you may use the `PARAMETERS_FILE` option to set the path to your file.

```bash
make PARAMETERS_FILE=my-custom-parameters.tfvars
```

### Destroy

To destroy the deployment, type:

```bash
make destroy
```

## Verify Installation

After [installing ArmoniK](./1.deployment.md), it is time to execute some simple tests to check that everything is working as expected. In order to do that, the ArmoniK team is providing three simple tests to verify that the deployment went well.

### Seq

First of all, you can try to connect to the log server [Seq](https://datalust.co/) to check that it is working correctly.

You can find the Seq URL printed on your console after the deployment.

::alert{type="info"}
You can also retrieve the `seq.web_url` from the Terraform outputs `monitoring/generated/monitoring-output.json`. The default port is `8080` but the ip address can be different depending on your machine.
::

Example:

```bash [shell]
http://<ip_address>:8080
```

<!-- TODO: Link 'enable it' with guide about https -->
No credentials are required to connect to Seq by default. Also, connexion is not encrypted by default (no HTTPS) but you can enable it.

### Admin GUI

You can also try to connect to the [ArmoniK Admin GUI](https://aneoconsulting.github.io/ArmoniK.Admin.GUI/) to check that it is working correctly.

You can find the Admin GUI URL printed on your console after the deployment.

<!-- TODO: need to be confirmed -->
::alert{type="info"}
You can also retrieve the `armonik.admin_gui_url` from the Terraform outputs `armonik/generated/armonik-output.json`. The default port is `5000` but the ip address can be different depending on your machine.
::

Example:

```bash [shell]
http://<ip_address>:5000
```

### HTC Mock

<!-- TODO: Create a sample in order to test installation (no more Symphony or DataSynapse) -->
You can now run [HTC Mock](https://aneoconsulting.github.io/ArmoniK/guide/how-to/how-to-use-htc-mock) to see a mock utilisation of ArmoniK and verify your installation.

::alert{type="info"}
You can check the logs using Seq.
::
