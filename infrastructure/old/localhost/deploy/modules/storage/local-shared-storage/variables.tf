# Global variables
variable "namespace" {
  description = "Namespace of ArmoniK resources"
  type        = string
}

# Parameters for shared storage
variable "local_shared_storage" {
  description = "A local persistent volume used as NFS"
  type        = object({
    storage_class           = object({
      name = string
    }),
    persistent_volume       = object({
      name      = string
      size      = string
      host_path = string
    }),
    persistent_volume_claim = object({
      name = string
      size = string
    })
  })
}