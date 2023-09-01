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

variable "armonik_versions" {
  description = "Versions of all the ArmoniK components"
  type        = map(string)
}

variable "armonik_images" {
  description = "Image names of all the ArmoniK components"
  type        = map(set(string))
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
    image_name         = optional(string, "symptoma/activemq"),
    image_tag          = optional(string),
    node_selector      = optional(map(string), {})
    image_pull_secrets = optional(string, "")
  })
  default = {}
}

# Parameters for MongoDB
variable "mongodb" {
  description = "Parameters of MongoDB"
  type = object({
    image_name         = optional(string, "mongo"),
    image_tag          = optional(string),
    node_selector      = optional(map(string), {})
    image_pull_secrets = optional(string, "")
    replicas_number    = optional(number, 1)
  })
  default = {}
}

# Parameters for Redis
variable "redis" {
  description = "Parameters of Redis"
  type = object({
    image_name         = optional(string, "redis"),
    image_tag          = optional(string),
    node_selector      = optional(map(string), {})
    image_pull_secrets = optional(string, "")
    max_memory         = optional(string, "12000mb")
  })
  default = {}
}

# Parameters for minio
variable "minio" {
  description = "Parameters of minio"
  type = object({
    image_name         = optional(string, "minio/minio")
    image_tag          = optional(string)
    node_selector      = optional(map(string), {})
    image_pull_secrets = optional(string, "")
    default_bucket     = optional(string, "minioBucket")
    host               = optional(string, "minio")
  })
  default = null

}

# Parameters for minio file storage
variable "minio_s3_fs" {
  description = "Parameters of Minio"
  type = object({
    image_name         = optional(string, "minio/minio")
    image_tag          = optional(string)
    node_selector      = optional(map(string), {})
    image_pull_secrets = optional(string, "")
    default_bucket     = optional(string, "minioBucket")
    host               = optional(string, "minio-s3-fs")
  })
  default = null
}