variable "nfs_server_provisioner_chart_url" {
  description = "NFS server provisioner chart URL"
  default = "../charts"
}

variable "replica_count" {
  description = "Replica count for NFS server provisioner"
  default = "1"
}

variable "persistence" {
  description = "Enable persistence"
  default = false
}

variable "storage_class_name" {
  description = "Name of the storage class"
  default = "nfs"
}

variable "access_mode" {
  description = "Access mode to the volume"
  default = "ReadWriteMany"
}

variable "volume_size" {
  description = "Size of the volume"
  default = "2Gi"
}

variable "create_storage_class" {
  description = "Create a storage class"
  default = true
}

variable "default_class" {
  description = "Default storage class"
  default = true
}

variable "nfs_persistent_volume_claim_name" {
  description = "Name of the NFS persistent volume claim"
  default = "nfs-pvc"
}

variable "nfs_persistent_volume_claim_size" {
  description = "Minimum amount of compute resources required"
  default = "2Gi"
}

variable "nfs_persistent_volume_name" {
  description = "Name of the NFS persistent volume"
  default = "nfs-pv"
}

variable "nfs_persistent_volume_size" {
  description = "Size of the NFS persistent volume"
  default = "10Gi"
}

variable "local_pv_path" {
  description = "Host path to the local persistent volume"
  default = "$(PWD)/nfs-local"
}

variable "persistent_volume_mode" {
  description = "Persistent volume mode"
  default = "Filesystem"
}

variable "persistent_volume_reclaim_policy" {
  description = "What happens to a persistent volume when released from its claim"
  default = "Delete"
}