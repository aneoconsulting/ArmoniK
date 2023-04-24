# The namespace in Kubernetes for ArmoniK
export ARMONIK_KUBERNETES_NAMESPACE="armonik"
# The filesystem on your local machine shared with workers of ArmoniK
export ARMONIK_SHARED_HOST_PATH="${HOME}/data"
# The type of the filesystem which can be one of HostPath or NFS
export ARMONIK_FILE_STORAGE_FILE="HostPath"
# The IP of the network filesystem if ARMONIK_SHARED_HOST_PATH=NFS
export ARMONIK_FILE_SERVER_IP=""
# The namespace in Kubernetes for KEDA
export KEDA_KUBERNETES_NAMESPACE="default"
# The namespace in Kubernetes for metrics server
export METRICS_SERVER_KUBERNETES_NAMESPACE="kube-system"
