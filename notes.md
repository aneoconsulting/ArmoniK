# Running ArmoniK on Grid'5000

Connect ot the frontend of Nancy.

```bash
~$ ssh qdelamea@access.grid5000.fr
~$ ssh nancy
```

## Prerequisites

To deploy a Kubernetes cluster on g5k, you need terraform
and kubectl on the **frontend**. However, there is no root
access on the frontend and theses binaries are not avialable
through Guix or the module utility.

*Remark*: It is easy to install everything from a node reserved
but the deployment fail!

The only way I found to install dependencies is to install through curl.
Then created a 'bin' directory in the home directory and added it to the PATH.

```bash
curl
unzip terraform.zip
curl
chmod +x ./kubectl
mkdir bin
mv terraform bin
mv kubectl vin
export PATH="/home/qdelamea/bin:${PATH}"
```

The follow the tuto to deploy the Kubernetes cluster.
Then use the localhost deployment of this branch to deploy.
Here are the modification maed to the parameters.tfvars:
- kube_config_context = "local"
So far the deployment timeouts when trying to deploy
the ingress. Next, try with the following modification.
- ingress.service_type = "ClusterIP"

There is no access to Docker on the frontend. So, jobs
on ArmoniK will be executed using Kubernetes Jobs.

