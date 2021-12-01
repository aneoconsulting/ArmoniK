# Global parameters
namespace = {
  description = "Namespace of ArmoniK resources"
  type        = string
}

k8s_config_path = {
  description = "Path pf the configuration file of K8s"
  type        = string
}

k8s_config_context = {
  description = "Context of K8s"
  type        = string
}

# Parameters for object storage
object_storage = {
  description = "Parameters of object storage of ArmoniK"
  type        = {
    replicas = number
    port     = number
    secret   = string
  }
}

# Parameters for table storage
table_storage = {
  description = "Parameters of table storage of ArmoniK"
  type        = {
    replicas = number
    port     = number
  }
}

# Parameters for queue storage
queue_storage = {
  description = "Parameters of queue storage of ArmoniK"
  type        = {
    replicas = number
    port     = list({
      name        = string
      port        = number
      target_port = number
      protocol    = string
    })
    secret   = string
  }
}

# Parameters for shared storage
shared_storage = {
  description = "A local persistent volume used as NFS"
  type        = {
    storage_class           = {
      provisioner            = string
      name                   = string
      volume_binding_mode    = string
      allow_volume_expansion = bool
    }
    persistent_volume       = {
      name                             = string
      persistent_volume_reclaim_policy = string
      access_modes                     = list(string)
      size                             = string
      host_path                        = string
    }
    persistent_volume_claim = {
      name         = string
      access_modes = list(string)
      size         = string
    }
  }
}

# ArmoniK
armonik = {
  description = "Components of ArmoniK"
  type        = {
    control_plane    = {
      replicas          = number
      image             = string
      tag               = string
      image_pull_policy = string
      port              = number
    }
    compute_plane    = {
      replicas      = number
      polling_agent = {
        image             = string
        tag               = string
        image_pull_policy = string
        limits            = {
          cpu    = string
          memory = string
        }
        requests          = {
          cpu    = string
          memory = string
        }
      }
      compute       = {
        image             = string
        tag               = string
        image_pull_policy = string
        limits            = {
          cpu    = string
          memory = string
        }
        requests          = {
          cpu    = string
          memory = string
        }
      }
    }
    storage_services = {
      object_storage         = {
        type = string
        url  = string
        port = number
      }
      table_storage          = {
        type = string
        url  = string
        port = number
      }
      queue_storage          = {
        type = string
        url  = string
        port = number
      }
      lease_provider_storage = {
        type = string
        url  = string
        port = number
      }
      shared_storage         = {
        claim_name  = string
        target_path = string
      }
    }
  }
}