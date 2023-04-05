# Global variables
variable "namespace" {
  description = "Namespace of ArmoniK resources"
  type        = string
}

# Parameters for MongoDB
variable "mongodb" {
  description = "Parameters of MongoDB"
  type = object({
    image              = string
    tag                = string
    node_selector      = any
    image_pull_secrets = string
    replicas_number    = number
  })
}

# Working dir
variable "working_dir" {
  description = "Working directory"
  type        = string
  default     = "../.."
}

# Persistent volume
variable "persistent_volume" {
  description = "Persistent volume info"
  type = object({
    storage_provisioner = string
    parameters          = map(string)
    # Resources for PVC
    resources = object({
      limits = object({
        storage = string
      })
      requests = object({
        storage = string
      })
    })
  })
}