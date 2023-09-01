# Troubleshooting

Things can go wrong. As a developer, you know this already. But what to do when something goes wrong in ArmoniK ?

This section will give you tips to check and fix problems for those times when it just won’t work and you do not know why.
___

## Your deployment failed or is malfunctioning

First, note that if you deployment is local, MongoDB and Redis certificates are only available for 7 days. Past this period, your deployment might encounter issues.
Our suggestion is to destroy your deployment and redeploy.
In the 0.1.0 version of the infrastructure, the default validity is set to 8760 hours (one year). You can set the certificate validity parameter before the deployment in the parameters.tfvars file.

To check if your deployment is ok, enter the command:

```bash [shell]
kubectl get po -A
```

This line allows you to check the status of all the pods. If every one of them is «Running» or «Completed», your deployment is operational.
___
::alert{type="info"}
To stop Terraform, we do **not** recommend using CTRL+C in the terminal. If Terraform CLI is interrupted (e.g. ctrl+c, SIGINT) during the apply phase (especially with a second interruption) then it will exit ungracefully (ex. Terraform state is corrupted). In this case, you will typically need to take manual repair actions before you can continue (which is usually very tedious.).
::
___

## Deployment is ok but tasks are not processed

If your deployment is ok, but tasks are not being processed, there are several solutions you can try.

### 1. Set the retry value in the task options to 1

This way, if the problem is an exception that would trigger a retry, the client will see the details on the first error.

### 2. Open Seq

Opening Seq will allow you to see the logs of the workers and ArmoniK. If you have no information on your workers, it means that either they are off (if you received an error that doesn't look like it's from your code, you may have given the wrong partition name) or that the Workers crashed and did not send any information to Seq.

### 3. Check if a pod is malfunctioning

Run the command line :

```bash [shell]
kubectl –n armonik get po -A
```

This command line will show you all the active pods in the armonik namespace. Once you located the malfunctioning pod, you can use :

```bash [shell]
kubectl –n armonik describe po <PodName>
```

This command line will show you the statuses of the pod's containers. If the pod crashes, you will get the reason in your terminal.
___

## How to stop a container

If you have a pod with a "Terminating" status and you want to force it to stop, you can do so with the command:

```bash [shell]
kubectl –n armonik delete po –force <PodName>
```

This command is to be used only if the ```kubectl delete po -n armonik <PodName>``` used to delete a pod has the pod stuck in a Terminating state for more than a few minutes. To check if the pod has been correctly stopped, run the command:

``` bash [shell]
kubectl –n armonik get po --field-selector metadata.name=<PodName>
```

The deleted pod should not appear in the list and you will have the following message: "No resources found in armonik namespace."
___

## My Worker is receiving a task but crashes. Why?

You might get some information by checking with Seq. However, in some rare cases, if the worker container crashed suddenly, some logs may not appear in Seq.

If you can not see the logs in Seq or if you prefer, you can check the logs directly with:

```bash [shell]
kubectl –n armonik logs <PodName> –f
```

This line will show you the logs of a container in the given pod if there is only one container within that pod. If there are multiple containers if your pod, then use the following command :

```bash [shell]
kubectl –n armonik logs <PodName> -c <containerName> -f
```

This command will give you the logs on the specified container and pod. You can add -f to have live feedback.
