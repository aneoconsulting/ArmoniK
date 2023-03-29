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

# Kubernetes namespace
variable "namespace" {
  description = "Kubernetes namespace for ArmoniK"
  type        = string
  default     = "armonik"
}

# Shared storage
variable "shared_storage" {
  description = "Shared storage infos"
  type = object({
    host_path         = string
    file_storage_type = string
    file_server_ip    = string
  })
}

# Parameters for ActiveMQ
variable "activemq" {
  description = "Parameters of ActiveMQ"
  type = object({
    image              = string
    tag                = string
    node_selector      = any
    image_pull_secrets = string
  })
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

# Parameters for Redis
variable "redis" {
  description = "Parameters of Redis"
  type = object({
    image              = string
    tag                = string
    node_selector      = any
    image_pull_secrets = string
    max_memory         = string
  })
  default = null
}

# Parameters for minio
variable "minio" {
  description = "Parameters of minio"
  type = object({
    image              = string
    tag                = string
    image_pull_secrets = string
    host               = string
    default_bucket     = string
    node_selector      = any
  })
  default = null
}