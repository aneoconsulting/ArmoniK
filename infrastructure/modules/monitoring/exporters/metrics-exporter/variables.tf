# Global variables
variable "namespace" {
  description = "Namespace of ArmoniK resources"
  type        = string
}

# Working dir
variable "working_dir" {
  description = "Working directory"
  type        = string
  default     = ".."
}

# List of needed storage
variable "storage_endpoint_url" {
  description = "List of storage needed by ArmoniK"
  type        = any
  validation {
    condition = length(setsubtract([
      "username", "password"
    ], try(var.storage_endpoint_url.mongodb.credentials.data_keys, []))) == 0
    error_message = "Kubernetes secret of MongoDB user credentials should have data keys: \"username\", \"password\""
  }
  validation {
    condition = length(setsubtract([
      "host", "port"
    ], try(var.storage_endpoint_url.mongodb.endpoints.data_keys, []))) == 0
    error_message = "Kubernetes secret of MongoDB endpoints should have data keys: \"host\", \"port\""
  }
}

# Docker image
variable "docker_image" {
  description = "Docker image for Metrics exporter"
  type = object({
    image              = string
    tag                = string
    image_pull_secrets = string
  })
}

# Node selector
variable "node_selector" {
  description = "Node selector for Metrics exporter"
  type        = any
  default     = {}
}

# Type of service
variable "service_type" {
  description = "Service type which can be: ClusterIP, NodePort or LoadBalancer"
  type        = string
}

# Extra configuration
variable "extra_conf" {
  description = "Add extra configuration in the configmaps"
  type        = map(string)
  default     = {}
}