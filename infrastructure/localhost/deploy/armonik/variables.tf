#Global variables
variable "namespace" {
  description = "Namespace of ArmoniK resources"
  type        = string
}

# ArmoniK control plane
variable "control_plane" {
  description = "Control plane of ArmoniK"
  type        = object({
    replicas          = number,
    image             = string,
    image_pull_policy = string,
    port              = number,
    storage_services  = object({
      object_storage         = object({ type = string, url = string, port = number }),
      table_storage          = object({ type = string, url = string, port = number }),
      queue_storage          = object({ type = string, url = string, port = number }),
      lease_provider_storage = object({ type = string, url = string, port = number }),
      shared_storage         = string
    })
  })
}
