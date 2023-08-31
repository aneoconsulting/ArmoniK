# AWS all in one deployment

Deploying on AWS is similar to deploying on localhost but with the necessity to deploy an S3 bucket first.

## Generate S3 bucket key

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

## Accessing Kubernetes cluster

To access your Kubernetes cluster, execute the following command after entering your settings in the 3 angle brackets:

```bash
aws --profile <AWS_PROFILE>​ eks update-kubeconfig --region <AWS_REGION> --name <NAME_AWS_EKS>​
```

or simply enter the following command:

```bash
export KUBECONFIG=<PATH_TO_AWS_FOLDER>/generated/kubeconfig
```

## Configuration

All parameters are contained in [`parameters.tfvars`](https://github.com/aneoconsulting/ArmoniK/blob/main/infrastructure/quick-deploy/aws/all-in-one/parameters.tfvars)

::alert{type="info"}
By default, all the cloud services are set to launch. To see what kind of parameters are available, read [`variables.tf`](https://github.com/aneoconsulting/ArmoniK/blob/main/infrastructure/quick-deploy/aws/all-in-one/variables.tf)
::

You can specify a custom parameter file. When executing the `make` command, you may use the `PARAMETERS_FILE` option to set the path to your file.

```bash
make PARAMETERS_FILE=my-custom-parameters.tfvars
```
