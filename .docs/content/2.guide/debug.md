<!-- TODO: Move it to Core -->

# Debug Informations to save the day

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
