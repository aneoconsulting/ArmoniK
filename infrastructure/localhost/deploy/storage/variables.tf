# Global variables
variable "namespace" {
  description = "Namespace of ArmoniK resources"
  type        = string
}

# Parameters for object storage
variable "object_storage" {
  description = "Parameters of object storage of ArmoniK"
  type        = object({
    replicas     = number,
    port         = number,
    secret       = string
  })
}

# Parameters for table storage
variable "table_storage" {
  description = "Parameters of table storage of ArmoniK"
  type        = object({
    replicas = number,
    port     = number
  })
}

# Parameters for queue storage
variable "queue_storage" {
  description = "Parameters of queue storage of ArmoniK"
  type        = object({
    replicas = number,
    port     = list(object({
      name        = string,
      port        = number,
      target_port = number,
      protocol    = string
    })),
    secret   = string
  })
}

# Parameters for shared storage
variable "shared_storage" {
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