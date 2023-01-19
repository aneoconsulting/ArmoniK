# Kubeconfig path
variable "k8s_config_path" {
  description = "Path of the configuration file of K8s"
  type        = string
  default     = "~/.kube/config"
}

# Kubeconfig context
variable "k8s_config_context" {
  description = "Context of K8s"
  type        = string
  default     = "default"
}

# Prefix
variable "prefix" {
  description = "Prefix used to name all the resources"
  type        = string
  default     = null # random
}

# Kubernetes namespace
variable "namespace" {
  description = "Kubernetes namespace for ArmoniK"
  type        = string
  default     = "armonik"
}

# Logging level
variable "logging_level" {
  description = "Logging level in ArmoniK"
  type        = string
  default     = "Information"
}

# Metrics Server
variable "metrics_server" {
  description = "Parameters of the metrics server"
  type = object({
    namespace          = optional(string, "kube-system"),
    image_name         = optional(string, "k8s.gcr.io/metrics-server/metrics-server"),
    image_tag          = optional(string, "v0.6.1"),
    image_pull_secrets = optional(string, ""),
    node_selector      = optional(any, {}),
    args = optional(list(string), [
      "--cert-dir=/tmp",
      "--kubelet-preferred-address-types=InternalIP,ExternalIP,Hostname",
      "--kubelet-use-node-status-port",
      "--metric-resolution=15s",
    ]),
    host_network = optional(bool, false),
  })
  default = null
}

# Keda
variable "keda" {
  description = "Keda configuration"
  type = object({
    namespace            = optional(string, "default")
    keda_image_name      = optional(string, "ghcr.io/kedacore/keda"),
    keda_image_tag       = optional(string, "2.8.0"),
    apiserver_image_name = optional(string, "ghcr.io/kedacore/keda-metrics-apiserver"),
    apiserver_image_tag  = optional(string, "2.8.0"),
    pull_secrets         = optional(string, ""),
    node_selector        = optional(any, {})
  })
  default = {}
}

# Shared storage
variable "shared_storage" {
  description = "Shared storage infos"
  type = object({
    host_path         = string
    file_storage_type = optional(string, "HostPath")
    file_server_ip    = optional(string, "")
  })
  default = null
}

# Parameters for ActiveMQ
variable "activemq" {
  description = "Parameters of ActiveMQ"
  type = object({
    image_name         = string
    image_tag          = string
    node_selector      = optional(any, {})
    image_pull_secrets = optional(string, "")
  })
}

# Parameters for MongoDB
variable "mongodb" {
  description = "Parameters of MongoDB"
  type = object({
    image_name         = string
    image_tag          = string
    node_selector      = optional(any, {})
    image_pull_secrets = optional(string, "")
  })
}

# Parameters for Redis
variable "redis" {
  description = "Parameters of Redis"
  type = object({
    image_name         = string
    image_tag          = string
    node_selector      = optional(any, {})
    image_pull_secrets = optional(string, "")
    max_memory         = optional(string, "8000gb")
  })
}


variable "seq" {
  description = "Seq configuration"
  type = object({
    image_name        = string
    image_tag         = string
    port              = optional(number, 8080)
    pull_secrets      = optional(string, "")
    service_type      = optional(string, "ClusterIP")
    node_selector     = optional(any, {})
    system_ram_target = optional(number, 0.2)
    authentication    = optional(bool, false)
  })
  default = null
}

variable "grafana" {
  description = "Grafana configuration"
  type = object({
    image_name     = string
    image_tag      = string
    port           = optional(number, 3000)
    pull_secrets   = optional(string, "")
    service_type   = optional(string, "ClusterIP")
    node_selector  = optional(any, {})
    authentication = optional(bool, false)
  })
  default = null
}

variable "node_exporter" {
  description = "Node exporter configuration"
  type = object({
    image_name    = string
    image_tag     = string
    pull_secrets  = optional(string, "")
    service_type  = optional(string, "ClusterIP")
    node_selector = optional(any, {})
  })
  default = null
}

variable "prometheus" {
  description = "Prometheus configuration"
  type = object({
    image_name    = string
    image_tag     = string
    pull_secrets  = optional(string, "")
    service_type  = optional(string, "ClusterIP")
    node_selector = optional(any, {})
  })
}

variable "metrics_exporter" {
  description = "Metrics exporter configuration"
  type = object({
    image_name    = string
    image_tag     = string
    pull_secrets  = optional(string, "")
    service_type  = optional(string, "ClusterIP")
    node_selector = optional(any, {})
  })
}

variable "partition_metrics_exporter" {
  description = "Partition metrics exporter configuration"
  type = object({
    image_name    = string
    image_tag     = string
    pull_secrets  = optional(string, "")
    service_type  = optional(string, "ClusterIP")
    node_selector = optional(any, {})
  })
  default = null
}

variable "fluent_bit" {
  description = "Fluent bit configuration"
  type = object({
    image_name     = string
    image_tag      = string
    pull_secrets   = optional(string, "")
    is_daemonset   = optional(bool, true)
    http_port      = optional(number, 2020)
    read_from_head = optional(bool, true)
    node_selector  = optional(any, {})
  })
}


# Polling delay to MongoDB
# according to the size of the task and/or the application
variable "mongodb_polling_delay" {
  description = "Polling delay to MongoDB according to the size of the task and/or the application"
  type = object({
    min_polling_delay = optional(string, "00:00:01")
    max_polling_delay = optional(string, "00:00:15")
  })
  default = {}
}

# Job to insert partitions in the database
variable "job_partitions_in_database" {
  description = "Job to insert partitions IDs in the database"
  type = object({
    name               = optional(string, "job-partitions-in-database")
    image              = string
    tag                = string
    image_pull_policy  = optional(string, "IfNotPresent")
    image_pull_secrets = optional(string, "")
    node_selector      = optional(any, {})
    annotations        = optional(any, {})
  })
}

# Parameters of control plane
variable "control_plane" {
  description = "Parameters of the control plane"
  type = object({
    name              = optional(string, "control-plane")
    service_type      = optional(string, "ClusterIP")
    replicas          = optional(number, 2)
    image             = string
    tag               = string
    image_pull_policy = optional(string, "IfNotPresent")
    port              = optional(number, 5001)
    limits = optional(object({
      cpu    = optional(string)
      memory = optional(string)
    }))
    requests = optional(object({
      cpu    = optional(string)
      memory = optional(string)
    }))
    image_pull_secrets = optional(string, "")
    node_selector      = optional(any, {})
    annotations        = optional(any, {})
    # KEDA scaler
    hpa               = optional(any)
    default_partition = string
  })
}

# Parameters of admin gui
variable "admin_gui" {
  description = "Parameters of the admin GUI"
  type = object({
    api = object({
      name  = optional(string, "admin-api")
      image = string
      tag   = string
      port  = optional(number, 3333)
      limits = optional(object({
        cpu    = optional(string)
        memory = optional(string)
      }))
      requests = optional(object({
        cpu    = optional(string)
        memory = optional(string)
      }))
    })
    app = object({
      name  = optional(string, "admin-app")
      image = string
      tag   = string
      port  = optional(number, 1080)
      limits = optional(object({
        cpu    = optional(string)
        memory = optional(string)
      }))
      requests = optional(object({
        cpu    = optional(string)
        memory = optional(string)
      }))
    })
    service_type       = optional(string, "ClusterIP")
    replicas           = optional(number, 1)
    image_pull_policy  = optional(string, "IfNotPresent")
    image_pull_secrets = optional(string, "")
    node_selector      = optional(any, {})
  })
}

# Parameters of the compute plane
variable "compute_plane" {
  description = "Parameters of the compute plane"
  type = map(object({
    replicas                         = optional(number, 1)
    termination_grace_period_seconds = optional(number, 30)
    image_pull_secrets               = optional(string, "IfNotPresent")
    node_selector                    = optional(any, {})
    annotations                      = optional(any, {})
    polling_agent = object({
      image             = string
      tag               = string
      image_pull_policy = optional(string, "IfNotPresent")
      limits = optional(object({
        cpu    = optional(string)
        memory = optional(string)
      }))
      requests = optional(object({
        cpu    = optional(string)
        memory = optional(string)
      }))
    })
    worker = list(object({
      name              = optional(string, "worker")
      image             = string
      tag               = string
      image_pull_policy = optional(string, "IfNotPresent")
      limits = optional(object({
        cpu    = optional(string)
        memory = optional(string)
      }))
      requests = optional(object({
        cpu    = optional(string)
        memory = optional(string)
      }))
    }))
    # KEDA scaler
    hpa = optional(any)
  }))
}

variable "ingress" {
  description = "Parameters of the ingress controller"
  type = object({
    name              = optional(string, "ingress")
    service_type      = optional(string, "LoadBalancer")
    replicas          = optional(number, 1)
    image             = string
    tag               = string
    image_pull_policy = optional(string, "IfNotPresent")
    http_port         = optional(number, 5000)
    grpc_port         = optional(number, 5001)
    limits = optional(object({
      cpu    = optional(string)
      memory = optional(string)
    }))
    requests = optional(object({
      cpu    = optional(string)
      memory = optional(string)
    }))
    image_pull_secrets    = optional(string, "")
    node_selector         = optional(any, "")
    annotations           = optional(any, {})
    tls                   = optional(bool, false)
    mtls                  = optional(bool, false)
    generate_client_cert  = optional(bool, true)
    custom_client_ca_file = optional(string, "")
  })
}

# Authentication behavior
variable "authentication" {
  description = "Authentication behavior"
  type = object({
    name                    = optional(string, "job-authentication-in-database")
    image                   = string
    tag                     = string
    image_pull_policy       = optional(string, "IfNotPresent")
    image_pull_secrets      = optional(string, "")
    node_selector           = optional(any, {})
    authentication_datafile = optional(string, "")
    require_authentication  = optional(bool, false)
    require_authorization   = optional(bool, false)
  })
}
