#Global variables
variable "namespace" {
  description = "Namespace of ArmoniK resources"
  type        = string
  default     = "armonik"
}

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

# Parameters for object storage
variable "object_storage" {
  description = "Parameters of object storage of ArmoniK"
  type        = object({
    replicas     = number,
    port         = number,
    certificates = map(string),
    secret       = string
  })
  default     = {
    replicas     = 1,
    port         = 6379,
    certificates = {
      cert_file    = "cert.crt",
      key_file     = "cert.key",
      ca_cert_file = "ca.crt"
    },
    secret       = "object-storage-secret"
  }
}

# Parameters for table storage
variable "table_storage" {
  description = "Parameters of table storage of ArmoniK"
  type        = object({
    replicas = number,
    port     = number
  })
  default     = {
    replicas = 1,
    port     = 27017
  }
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
  default     = {
    replicas = 1,
    port     = [
      { name = "dashboard", port = 8161, target_port = 8161, protocol = "TCP" },
      { name = "openwire", port = 61616, target_port = 61616, protocol = "TCP" },
      { name = "amqp", port = 5672, target_port = 5672, protocol = "TCP" },
      { name = "stomp", port = 61613, target_port = 61613, protocol = "TCP" },
      { name = "mqtt", port = 1883, target_port = 1883, protocol = "TCP" }
    ],
    secret   = "queue-storage-secret"
  }
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
      path                             = string
    }),
    persistent_volume_claim = object({
      name         = string,
      access_modes = list(string),
      size         = string
    })
  })
  default     = {
    storage_class           = {
      provisioner            = "kubernetes.io/no-provisioner",
      name                   = "nfs",
      volume_binding_mode    = "WaitForFirstConsumer",
      allow_volume_expansion = true
    },
    persistent_volume       = {
      name                             = "nfs-pv",
      persistent_volume_reclaim_policy = "Delete",
      access_modes                     = ["ReadWriteMany"],
      size                             = "10Gi",
      path                             = "./generated/data"
    },
    persistent_volume_claim = {
      name         = "nfs-pvc",
      access_modes = ["ReadWriteMany"],
      size         = "2Gi"
    }
  }
}

# ArmoniK
variable "armonik" {
  description = "Components of ArmoniK"
  type        = object({
    control_plane = object({
      replicas          = number,
      image             = string,
      tag               = string,
      image_pull_policy = string,
      port              = number,
    }),
    agent         = object({
      replicas      = number,
      polling_agent = object({
        image             = string,
        tag               = string,
        image_pull_policy = string,
        limits            = object({
          cpu    = string,
          memory = string
        }),
        requests          = object({
          cpu    = string,
          memory = string
        })
      }),
      compute       = object({
        image             = string,
        tag               = string,
        image_pull_policy = string,
        limits            = object({
          cpu    = string,
          memory = string
        }),
        requests          = object({
          cpu    = string,
          memory = string
        })
      }),
    })
  })
  default     = {
    control_plane = {
      replicas          = 1,
      image             = "dockerhubaneo/armonik_control",
      tag               = "dev-6276",
      image_pull_policy = "IfNotPresent",
      port              = 9000
    },
    agent         = {
      replicas      = 1,
      polling_agent = {
        image             = "dockerhubaneo/armonik_pollingagent",
        tag               = "dev-6276",
        image_pull_policy = "IfNotPresent",
        limits            = {
          cpu    = "100m",
          memory = "128Mi"
        },
        requests          = {
          cpu    = "100m",
          memory = "128Mi"
        }
      },
      compute       = {
        image             = "dockerhubaneo/armonik_compute",
        tag               = "dev-6276",
        image_pull_policy = "IfNotPresent",
        limits            = {
          cpu    = "920m",
          memory = "3966Mi"
        },
        requests          = {
          cpu    = "50m",
          memory = "3966Mi"
        }
      }
    }
  }
}