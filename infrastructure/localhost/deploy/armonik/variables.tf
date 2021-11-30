#Global variables
variable "namespace" {
  description = "Namespace of ArmoniK resources"
  type        = string
}

# ArmoniK
variable "armonik" {
  description = "Components of ArmoniK"
  type        = object({
    control_plane    = object({
      replicas          = number,
      image             = string,
      image_pull_policy = string,
      port              = number,
    }),
    agent            = object({
      replicas      = number,
      polling_agent = object({
        image                 = string,
        image_pull_policy     = string,
        limits                = object({
          cpu    = string,
          memory = string
        }),
        requests              = object({
          cpu    = string,
          memory = string
        }),
        object_storage_secret = string
      }),
      compute       = object({
        image             = string,
        image_pull_policy = string,
        port              = number,
        limits            = object({
          cpu    = string,
          memory = string
        }),
        requests          = object({
          cpu    = string,
          memory = string
        })
      }),
    }),
    storage_services = object({
      object_storage         = object({ type = string, url = string, port = number }),
      table_storage          = object({ type = string, url = string, port = number }),
      queue_storage          = object({ type = string, url = string, port = number }),
      lease_provider_storage = object({ type = string, url = string, port = number }),
      shared_storage         = string
    })
  })
}

