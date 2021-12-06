# Table of contents

1. [Destroy ArmoniK](#destroy-armonik)
2. [Delete generated files](#delete-generated-files)

# Destroy ArmoniK <a name="destroy-armonik"></a>

To destroy ArmoniK resources and storage services in Kubernetes:

1. in directory [deploy/](../deploy):

```bash
cd ./deploy
```

2. execute the commandline:

```bash
make destroy CONFIG_FILE=<Your configuration file> 
```

# Delete generated files <a name="delete-generated-files"></a>

During the deployment, Terraform has generated some files as logs, states or Kubernetes configmaps in
directory `generated/`.

To clean and delete these files, execute:

```bash
make clean
```