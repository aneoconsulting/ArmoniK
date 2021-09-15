# Debug Informations to save the day

## While updating OpenAPI
```bash
dotnet nuget locals all --clear
```

## When nginx does not deploy
Delete the nginx namespace
```bash
kubectl delete namespaces ingress-nginx
```

## List all on-going deployments
```bash
kubectl get deployments --all-namespaces
```

## Delete redis deployment
```bash
kubectl delete deployment -n default redis
```

## Fast image redeployment
Only re-compile the targeted image, use image_pull_policy = Always instead of IfNotPresent and delete the po in order to pull the new image. It works well for the lambda and the applications (single task).

Re-compile one lambda
```bash
make -C source/control_plane/python/lambda/get_results/ lambda-get-results
make -C source/control_plane/python/lambda/submit_tasks lambda-submit-tasks
```

Re-comile client only (without dependencies)
```bash
make -C examples/mock_integration/Client/ build
```

## Debug C# container with Visual Studio Code
### Steps

- Compile the project on Debug mode with the flag `BUILD_TYPE=Debug`
- Install Kubernetes extension in VSC
- install vsdbg in the image either by adding the following command in the Dockerfile or executing it after connecting to the running image
```bash
curl -sSL https://aka.ms/getvsdbgsh | /bin/sh /dev/stdin -v latest -l /vsdbg
```
- Go in the Kubernets tab, select the node containing the code to debug and Right Click -> Debug (Attach)
- You can debug in the Debug tab !

### Sources
[https://www.hanselman.com/blog/remote-debugging-a-net-core-linux-app-in-wsl2-from-visual-studio-on-windows](https://www.hanselman.com/blog/remote-debugging-a-net-core-linux-app-in-wsl2-from-visual-studio-on-windows)
[https://code.visualstudio.com/docs/remote/attach-container](https://code.visualstudio.com/docs/remote/attach-container)
[https://okteto.com/blog/remote-kubernetes-development/](https://okteto.com/blog/remote-kubernetes-development/)