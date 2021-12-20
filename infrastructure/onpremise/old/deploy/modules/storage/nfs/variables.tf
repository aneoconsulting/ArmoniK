# Global variables
variable "namespace" {
  description = "Namespace of ArmoniK resources"
  type        = string
}

# Parameters for shared storage
variable "nfs" {
  description = "A local persistent volume used as NFS"
  type        = object({
    server                  = string
    path                    = string
    access_modes            = list(string)
    size                    = string
    storage_class           = object({
      name        = string
      provisioner = string
    })
    persistent_volume       = object({
      name                             = string
      persistent_volume_reclaim_policy = string
    })
    persistent_volume_claim = object({
      name = string
    })
  })
}