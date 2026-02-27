# Kubernetes deployment

If you want to deploy ArmoniK on Kubernetes, this section is for you.


## Clone ArmoniK


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

## Configuration

All parameters are contained in [`parameters.tfvars`](https://github.com/aneoconsulting/ArmoniK/blob/main/infrastructure/quick-deploy/localhost/parameters.tfvars)



```{note}

By default, all the cloud services are set to launch. To see what kind of parameters are available, read [`variables.tf`](https://github.com/aneoconsulting/ArmoniK/blob/main/infrastructure/quick-deploy/localhost/variables.tf)

```

You can specify a custom parameter file. When executing the `make` command, you may use the `PARAMETERS_FILE` option to set the path to your file.

```bash
make PARAMETERS_FILE=my-custom-parameters.tfvars
```

## Custom infrastructure version

If you need to fetch a specific version of the infrastructure, you can set the `MODULES_VERSION` parameter with the tag or branch you want to use.


```bash
# Fetch the main branch of the infrastructure and deploy
make MODULES_VERSION=main deploy
```
If `MODULES_VERSION` is empty, the current version of the infra folder will be used (`generated/infra-modules`).

```bash
# Deploy without fetching any specific tag or branch
make MODULES_VERSION= deploy
```

## Destroy

To destroy the deployment, type:

```bash
make destroy
```
