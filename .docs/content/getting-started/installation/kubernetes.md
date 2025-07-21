# Kubernetes Installation

If you already have a K3s installation, start by uninstalling it properly.

## Step 1: Stop the K3s service

```bash
sudo systemctl stop k3s
```

## Step 2: Run the uninstall script

K3s provides an uninstall script to remove all installed components.

```bash
sudo /usr/local/bin/k3s-uninstall.sh
```



## Step 3: Clean up remaining files (optional)

After the uninstall script, you can also remove any remaining K3s and Kubernetes files:

```bash
sudo rm -rf /etc/rancher/k3s
sudo rm -rf /var/lib/rancher
sudo rm -rf /var/lib/kubelet
sudo rm -rf ~/.kube
```

>**Note**: This step completely removes all K3s configuration and data. Only use this if you want a completely clean installation.

# K3s Installation

## Step 1: Run the installation script

### Option A: Use ArmoniK's installation script (Recommended)
Use the installation script available here: [infrastructure/utils/scripts/installation/prerequisites/install-k3s.sh](https://github.com/aneoconsulting/ArmoniK/blob/main/infrastructure/utils/scripts/installation/prerequisites/install-k3s.sh)

### Option B: Use the official installation script
You can also use the official installation script to install K3s:
```bash
curl -sfL https://get.k3s.io | sh -s - --write-kubeconfig-mode 644 --docker
```



## Step 2: Configure kubeconfig for your user (optional)

In case your Kube config was not created during installation:
- Create the kube directory
- Copy your kube config to a new config file
- Adjust permissions

```bash
mkdir -p ~/.kube
sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
sudo chown $(id -u):$(id -g) ~/.kube/config
```

## Step 3: Verify the installation

Ensure K3s is running and kubectl can access the cluster.

```bash
sudo systemctl status k3s
kubectl get nodes
```

## Certificate Verification

### Step 1: Check certificates in kubeconfig

Ensure certificates are properly configured in the kubeconfig file.

```bash
cat ~/.kube/config
```

You should see entries for certificate-authority-data, client-certificate-data, and client-key-data.

## Cluster Access Testing

### Step 1: Test cluster access with kubectl

Verify you can access the cluster and list pods in all namespaces.

```bash
kubectl get pods --all-namespaces
```

## Troubleshooting

### Check K3s logs

If you encounter issues, check the K3s logs for more details.

```bash
sudo journalctl -u k3s
```
