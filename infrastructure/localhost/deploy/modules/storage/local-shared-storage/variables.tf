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
      provisioner            = string,
      name                   = string,
      volume_binding_mode    = string,
      allow_volume_expansion = bool
    }),
    persistent_volume       = object({
      name                             = string,
      persistent_volume_reclaim_policy = string,
      access_modes                     = list(string),
      size                             = string,
      host_path                        = string
    }),
    persistent_volume_claim = object({
      name         = string,
      access_modes = list(string),
      size         = string
    })
  })
}