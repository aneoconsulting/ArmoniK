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
    image_name         = optional(string, "registry.k8s.io/metrics-server/metrics-server"),
    image_tag          = optional(string),
    image_pull_secrets = optional(string, ""),
    node_selector      = optional(any, {}),
    args = optional(list(string), [
      "--cert-dir=/tmp",
      "--kubelet-preferred-address-types=InternalIP,ExternalIP,Hostname",
      "--kubelet-use-node-status-port",
      "--metric-resolution=15s",
      "--kubelet-insecure-tls"
    ]),
    host_network          = optional(bool, false),
    helm_chart_repository = optional(string)
    helm_chart_version    = optional(string, "3.8.3")
  })
  default = null
}

# Keda
variable "keda" {
  description = "Keda configuration"
  type = object({
    namespace                       = optional(string, "default")
    keda_image_name                 = optional(string, "ghcr.io/kedacore/keda"),
    keda_image_tag                  = optional(string),
    apiserver_image_name            = optional(string, "ghcr.io/kedacore/keda-metrics-apiserver"),
    apiserver_image_tag             = optional(string),
    pull_secrets                    = optional(string, ""),
    node_selector                   = optional(any, {})
    metrics_server_dns_policy       = optional(string, "ClusterFirst")
    metrics_server_use_host_network = optional(bool, false)
    helm_chart_repository           = optional(string)
    helm_chart_version              = optional(string)
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
    image_name            = optional(string, "symptoma/activemq")
    image_tag             = optional(string)
    node_selector         = optional(any, {})
    image_pull_secrets    = optional(string, "")
    adapter_class_name    = optional(string, "ArmoniK.Core.Adapters.Amqp.QueueBuilder")
    adapter_absolute_path = optional(string, "/adapters/queue/amqp/ArmoniK.Core.Adapters.Amqp.dll")
  })
  default = {}
}

# Parameters for MongoDB
variable "mongodb" {
  description = "Parameters of MongoDB"
  type = object({
    image_name         = optional(string, "mongo")
    image_tag          = optional(string)
    node_selector      = optional(any, {})
    image_pull_secrets = optional(string, "")
    replicas_number    = optional(number, 1)
  })
  default = {}
}

# Parameters for Redis
variable "redis" {
  description = "Parameters of Redis"
  type = object({
    image_name         = optional(string, "redis")
    image_tag          = optional(string)
    node_selector      = optional(any, {})
    image_pull_secrets = optional(string, "")
    max_memory         = optional(string, "8000gb")
  })
  default = null
}

# Parameters for Minio
variable "minio" {
  description = "Parameters of Minio"
  type = object({
    image_name         = optional(string, "minio/minio")
    image_tag          = optional(string)
    node_selector      = optional(any, {})
    image_pull_secrets = optional(string, "")
    default_bucket     = optional(string, "minioBucket")
    host               = optional(string, "minio")
  })
  default = null
}

# Parameters for Minio file storage
variable "minio_s3_fs" {
  description = "Parameters of Minio"
  type = object({
    image_name         = optional(string, "minio/minio")
    image_tag          = optional(string)
    node_selector      = optional(any, {})
    image_pull_secrets = optional(string, "")
    default_bucket     = optional(string, "minioBucket")
    host               = optional(string, "minio-s3-fs")
  })
  default = null
}

variable "seq" {
  description = "Seq configuration"
  type = object({
    image_name        = optional(string, "datalust/seq")
    image_tag         = optional(string)
    port              = optional(number, 8080)
    pull_secrets      = optional(string, "")
    service_type      = optional(string, "ClusterIP")
    node_selector     = optional(any, {})
    system_ram_target = optional(number, 0.2)
    authentication    = optional(bool, false)
    cli_image_name    = optional(string, "datalust/seqcli")
    cli_image_tag     = optional(string)
    cli_pull_secrets  = optional(string, "")
    retention_in_days = optional(string, "2d")
  })
  default = {}
}

variable "grafana" {
  description = "Grafana configuration"
  type = object({
    image_name     = optional(string, "grafana/grafana")
    image_tag      = optional(string)
    port           = optional(number, 3000)
    pull_secrets   = optional(string, "")
    service_type   = optional(string, "ClusterIP")
    node_selector  = optional(any, {})
    authentication = optional(bool, false)
  })
  default = {}
}

variable "node_exporter" {
  description = "Node exporter configuration"
  type = object({
    image_name    = optional(string, "prom/node-exporter")
    image_tag     = optional(string)
    pull_secrets  = optional(string, "")
    service_type  = optional(string, "ClusterIP")
    node_selector = optional(any, {})
  })
  default = {}
}

variable "prometheus" {
  description = "Prometheus configuration"
  type = object({
    image_name    = optional(string, "prom/prometheus")
    image_tag     = optional(string)
    pull_secrets  = optional(string, "")
    service_type  = optional(string, "ClusterIP")
    node_selector = optional(any, {})
  })
  default = {}
}

variable "metrics_exporter" {
  description = "Metrics exporter configuration"
  type = object({
    image_name    = optional(string, "dockerhubaneo/armonik_control_metrics")
    image_tag     = optional(string)
    pull_secrets  = optional(string, "")
    service_type  = optional(string, "ClusterIP")
    node_selector = optional(any, {})
    extra_conf    = optional(map(string), {})
  })
  default = {}
}

variable "partition_metrics_exporter" {
  description = "Partition metrics exporter configuration"
  type = object({
    image_name    = optional(string, "dockerhubaneo/armonik_control_partition_metrics")
    image_tag     = optional(string)
    pull_secrets  = optional(string, "")
    service_type  = optional(string, "ClusterIP")
    node_selector = optional(any, {})
    extra_conf    = optional(map(string), {})
  })
  default = null
}

variable "fluent_bit" {
  description = "Fluent bit configuration"
  type = object({
    image_name     = optional(string, "fluent/fluent-bit")
    image_tag      = optional(string)
    pull_secrets   = optional(string, "")
    is_daemonset   = optional(bool, true)
    http_port      = optional(number, 2020)
    read_from_head = optional(bool, true)
    node_selector  = optional(any, {})
    parser         = optional(string, "docker")
  })
  default = {}
}

# Extra configuration
variable "extra_conf" {
  description = "Add extra configuration in the configmaps"
  type = object({
    compute = optional(map(string), {})
    control = optional(map(string), {})
    core    = optional(map(string), {})
    log     = optional(map(string), {})
    polling = optional(map(string), {})
    worker  = optional(map(string), {})
  })
  default = {}
}

# Job to insert partitions in the database
variable "job_partitions_in_database" {
  description = "Job to insert partitions IDs in the database"
  type = object({
    name               = optional(string, "job-partitions-in-database")
    image              = optional(string, "rtsp/mongosh")
    tag                = optional(string)
    image_pull_policy  = optional(string, "IfNotPresent")
    image_pull_secrets = optional(string, "")
    node_selector      = optional(any, {})
    annotations        = optional(any, {})
  })
  default = {}
}

# Parameters of control plane
variable "control_plane" {
  description = "Parameters of the control plane"
  type = object({
    name                 = optional(string, "control-plane")
    service_type         = optional(string, "ClusterIP")
    replicas             = optional(number, 1)
    image                = optional(string, "dockerhubaneo/armonik_control")
    tag                  = optional(string)
    image_pull_policy    = optional(string, "IfNotPresent")
    port                 = optional(number, 5001)
    service_account_name = optional(string, "")
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
    name  = optional(string, "admin-app")
    image = optional(string, "dockerhubaneo/armonik_admin_app")
    tag   = optional(string)
    port  = optional(number, 1080)
    limits = optional(object({
      cpu    = optional(string)
      memory = optional(string)
    }))
    requests = optional(object({
      cpu    = optional(string)
      memory = optional(string)
    }))
    service_type       = optional(string, "ClusterIP")
    replicas           = optional(number, 1)
    image_pull_policy  = optional(string, "IfNotPresent")
    image_pull_secrets = optional(string, "")
    node_selector      = optional(any, {})
  })
  default = {}
}

# Deprecated, must be removed in a future version
# Parameters of admin gui v0.9
variable "admin_0_9_gui" {
  description = "Parameters of the admin GUI v0.9"
  type = object({
    name  = optional(string, "admin-app")
    image = optional(string, "dockerhubaneo/armonik_admin_app")
    tag   = optional(string, "0.9.5")
    port  = optional(number, 1080)
    limits = optional(object({
      cpu    = optional(string)
      memory = optional(string)
    }))
    requests = optional(object({
      cpu    = optional(string)
      memory = optional(string)
    }))
    service_type       = optional(string, "ClusterIP")
    replicas           = optional(number, 1)
    image_pull_policy  = optional(string, "IfNotPresent")
    image_pull_secrets = optional(string, "")
    node_selector      = optional(any, {})
  })
  default = {}
}

# Deprecated, must be removed in a future version
# Parameters of admin gui v0.8 (previously called old admin gui)
variable "admin_0_8_gui" {
  description = "Parameters of the admin GUI v0.8"
  type = object({
    api = optional(object({
      name  = optional(string, "admin-api")
      image = optional(string, "dockerhubaneo/armonik_admin_api")
      tag   = optional(string, "0.8.1")
      port  = optional(number, 3333)
      limits = optional(object({
        cpu    = optional(string)
        memory = optional(string)
      }))
      requests = optional(object({
        cpu    = optional(string)
        memory = optional(string)
      }))
    }), {})
    app = optional(object({
      name  = optional(string, "admin-old-gui")
      image = optional(string, "dockerhubaneo/armonik_admin_app")
      tag   = optional(string, "0.8.1")
      port  = optional(number, 1080)
      limits = optional(object({
        cpu    = optional(string)
        memory = optional(string)
      }))
      requests = optional(object({
        cpu    = optional(string)
        memory = optional(string)
      }))
    }), {})
    service_type       = optional(string, "ClusterIP")
    replicas           = optional(number, 1)
    image_pull_policy  = optional(string, "IfNotPresent")
    image_pull_secrets = optional(string, "")
    node_selector      = optional(any, {})
  })
  default = {}
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
    service_account_name             = optional(string, "")
    polling_agent = object({
      image             = optional(string, "dockerhubaneo/armonik_pollingagent")
      tag               = optional(string)
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
      tag               = optional(string)
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
    image             = optional(string, "nginxinc/nginx-unprivileged")
    tag               = optional(string)
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
    node_selector         = optional(any, {})
    annotations           = optional(any, {})
    tls                   = optional(bool, false)
    mtls                  = optional(bool, false)
    generate_client_cert  = optional(bool, true)
    custom_client_ca_file = optional(string, "")
  })
  default = {}
}

# Authentication behavior
variable "authentication" {
  description = "Authentication behavior"
  type = object({
    name                    = optional(string, "job-authentication-in-database")
    image                   = optional(string, "rtsp/mongosh")
    tag                     = optional(string)
    image_pull_policy       = optional(string, "IfNotPresent")
    image_pull_secrets      = optional(string, "")
    node_selector           = optional(any, {})
    authentication_datafile = optional(string, "")
    require_authentication  = optional(bool, false)
    require_authorization   = optional(bool, false)
  })
  default = {}
}

# Extra configuration for jobs connecting to database
variable "jobs_in_database_extra_conf" {
  description = "Add extra configuration in the configmaps for jobs connecting to database"
  type        = map(string)
  default     = {}
}

variable "armonik_versions" {
  description = "Versions of all the ArmoniK components"
  type = object({
    infra     = string
    core      = string
    api       = string
    gui       = string
    extcsharp = string
    samples   = string
  })
}

variable "armonik_images" {
  description = "Image names of all the ArmoniK components"
  type = object({
    infra     = set(string)
    core      = set(string)
    api       = set(string)
    gui       = set(string)
    extcsharp = set(string)
    samples   = set(string)
  })
}

variable "image_tags" {
  description = "Tags of images used"
  type        = map(string)
}

variable "helm_charts" {
  description = "Versions of helm charts repositories"
  type = map(object({
    repository = string
    version    = string
  }))
}

variable "environment_description" {
  description = "Description of the environment"
  type        = any
  default     = null
}
