variable "namespace" {
  description = "Namespace"
  default     = "default"
}

variable "storage_class_name" {
  description = "Name of the storage class"
  default     = "nfs"
}

variable "storage_provisioner" {
  description = "Storage provisioner (https://kubernetes.io/docs/concepts/storage/storage-classes/)"
  default     = "kubernetes.io/no-provisioner"
}

variable "volume_binding_mode" {
  description = "Indicates when volume binding and dynamic provisioning should occur"
  default     = "WaitForFirstConsumer"
}

variable "allow_volume_expansion" {
  description = "Indicates whether the storage class allow volume expand"
  default     = true
}

variable "persistent_volume_name" {
  description = "Name of the NFS persistent volume"
  default = "nfs-pv"
}

variable "access_mode" {
  description = "Access mode to the volume"
  default = "ReadWriteMany"
}

variable "persistent_volume_reclaim_policy" {
  description = "What happens to a persistent volume when released from its claim"
}

variable "persistent_volume_size" {
  description = "Size of the NFS persistent volume"
}

variable "persistent_volume_claim_name" {
  description = "Name of the NFS persistent volume claim"
  default = "nfs-pvc"
}

variable "persistent_volume_claim_size" {
  description = "Minimum amount of compute resources required"
}

variable "persistent_volume_host_path" {
  description = "Host path"
}