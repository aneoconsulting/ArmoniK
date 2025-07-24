# K3S Installation

If you already have a K3s installation, start by [uninstalling it](https://docs.k3s.io/installation/uninstall) properly.


## Step 1: Run the installation script

### Option A: Use custom installation script (Recommended)
Use our installation script available here: [tools/install/k3s.sh](https://github.com/aneoconsulting/ArmoniK/blob/main/tools/install/k3s.sh)

### Option B: Use the official installation script
You can also use the official installation script to [install K3s](https://docs.k3s.io/quick-start)


## Step 2: Verify the installation

Ensure K3s is running and kubectl can access the cluster.

```bash
sudo systemctl status k3s
kubectl get nodes
```


### Troubleshooting: Kube Configuration



> **Note**: If your kube configuration was not created during installation or if you get permission errors, you can manually configure it:
> 
> - Create the kube directory
> - Copy your kube config to a new config file  
> - Adjust permissions
> 
> ```bash
> mkdir -p ~/.kube
> sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
> sudo chown $(id -u):$(id -g) ~/.kube/config
> ```

