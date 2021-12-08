#Global variables
variable "namespace" {
  description = "Namespace of ArmoniK resources"
  type        = string
}

# number of queues according to priority of tasks
variable "max_priority" {
  description = "Number of queues according to the priority of tasks"
  type        = number
}

# ArmoniK
variable "armonik" {
  description = "Components of ArmoniK"
  type        = object({
    control_plane    = object({
      replicas          = number
      image             = string
      tag               = string
      image_pull_policy = string
      port              = number
    })
    compute_plane    = object({
      replicas      = number
      polling_agent = object({
        image             = string
        tag               = string
        image_pull_policy = string
        limits            = object({
          cpu    = string
          memory = string
        })
        requests          = object({
          cpu    = string
          memory = string
        })
      })
      compute       = list(object({
        name              = string
        port              = number
        image             = string
        tag               = string
        image_pull_policy = string
        limits            = object({
          cpu    = string
          memory = string
        })
        requests          = object({
          cpu    = string
          memory = string
        })
      }))
    })
    storage_services = object({
      object_storage_type         = string
      table_storage_type          = string
      queue_storage_type          = string
      lease_provider_storage_type = string
      resources                   = object({
        mongodb_endpoint_url  = string
        redis_endpoint_url    = string
        activemq_endpoint_url = string
      })
      shared_storage              = object({
        claim_name  = string
        target_path = string
      })
    })
  })
}

