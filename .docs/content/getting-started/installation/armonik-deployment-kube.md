# ArmoniK Deployment on Kubernetes

## Deploy


If you want to deploy on AWS, go to the dedicated section on [`AWS`](aws.md)

If you want to deploy on GCP, go to the dedicated section on [`GCP`](gcp.md)

To launch the deployment, go to the [`infrastructure/quick-deploy/localhost`](https://github.com/aneoconsulting/ArmoniK/tree/main/infrastructure/quick-deploy/localhost) directory:

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

## Destroy

To destroy the deployment, type:

```bash
make destroy
```

> **Note**: If the **armonik** namespace fails to delete after several minutes, you can force its deletion using the script [force-delete-namespace.sh](../../../../tools/force-delete-namespace.sh) with the parameter `armonik`:
