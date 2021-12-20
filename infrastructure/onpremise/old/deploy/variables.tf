# Global parameters
variable "k8s_config_path" {
  description = "Path pf the configuration file of K8s"
  type        = string
  default     = "~/.kube/config"
}

variable "k8s_config_context" {
  description = "Context of K8s"
  type        = string
  default     = "default"
}

variable "namespace" {
  description = "Namespace of ArmoniK resources"
  type        = string
  default     = "armonik"
}

# number of queues according to priority of tasks
variable "priority" {
  description = "Number of queues according to the priority of tasks"
  type        = number
  default     = 1
}

# MongoDB
variable "mongodb" {
  description = "Parameters of MongoDB"
  type        = object({
    replicas = number
    port     = number
  })
  default     = {
    replicas = 1
    port     = 27017
  }
}

# Local shared storage
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
  default     = {
    server                  = "ec2-52-53-217-211.us-west-1.compute.amazonaws.com"
    path                    = "/nfs"
    size                    = "10Gi"
    access_modes            = ["ReadWriteMany"]
    storage_class           = {
      name        = "nfs"
      provisioner = "kubernetes.io/no-provisioner"
    }
    persistent_volume       = {
      name                             = "nfs-pv"
      persistent_volume_reclaim_policy = "Recycle"
    }
    persistent_volume_claim = {
      name = "nfs-pvc"
    }
  }
}

# ArmoniK components
variable "armonik" {
  description = "Components of ArmoniK"
  type        = object({
    # ArmoniK contol plane
    control_plane    = object({
      replicas          = number
      image             = string
      tag               = string
      image_pull_policy = string
      port              = number
    })
    # ArmoniK compute plane
    compute_plane    = object({
      # number of replicas for each deployment of compute plane
      replicas      = number
      # ArmoniK polling agent
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
      # ArmoniK computes
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
    # Storage used by ArmoniK
    storage_services = object({
      object_storage         = object({
        type = string
        url  = string
        port = number
      })
      table_storage          = object({
        type = string
        url  = string
        port = number
      })
      queue_storage          = object({
        type = string
        url  = string
        port = number
      })
      lease_provider_storage = object({
        type = string
        url  = string
        port = number
      })
      shared_storage         = object({
        claim_name  = string
        target_path = string
      })
    })
  })
  default     = {
    control_plane    = {
      replicas          = 1
      image             = "dockerhubaneo/armonik_control"
      tag               = "dev-6276"
      image_pull_policy = "IfNotPresent"
      port              = 5001
    }
    compute_plane    = {
      replicas      = 1
      polling_agent = {
        image             = "dockerhubaneo/armonik_pollingagent"
        tag               = "dev-6276"
        image_pull_policy = "IfNotPresent"
        limits            = {
          cpu    = "100m"
          memory = "128Mi"
        }
        requests          = {
          cpu    = "100m"
          memory = "128Mi"
        }
      }
      compute       = [
        {
          name              = "compute"
          port              = 80
          image             = "dockerhubaneo/armonik_compute"
          tag               = "dev-6276"
          image_pull_policy = "IfNotPresent"
          limits            = {
            cpu    = "920m"
            memory = "3966Mi"
          }
          requests          = {
            cpu    = "50m"
            memory = "3966Mi"
          }
        }
      ]
    }
    storage_services = {
      object_storage         = {
        type = "MongoDB"
        url  = ""
        port = 0
      }
      table_storage          = {
        type = "MongoDB"
        url  = ""
        port = 0
      }
      queue_storage          = {
        type = "MongoDB"
        url  = ""
        port = 0
      }
      lease_provider_storage = {
        type = "MongoDB"
        url  = ""
        port = 0
      }
      shared_storage         = {
        claim_name  = "nfs-pvc"
        target_path = "/nfs"
      }
    }
  }
}