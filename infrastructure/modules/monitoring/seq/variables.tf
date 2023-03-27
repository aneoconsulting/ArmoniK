# Namespace
variable "namespace" {
  description = "Namespace of ArmoniK monitoring"
  type        = string
}

# Port
variable "port" {
  description = "Port for Seq service"
  type        = string
}

# Docker image
variable "docker_image" {
  description = "Docker image for Seq"
  type = object({
    image              = string
    tag                = string
    image_pull_secrets = string
  })
}

# Docker image cron
variable "docker_image_cron" {
  description = "Docker image cron for Seq"
  type = object({
    image              = string
    tag                = string
    image_pull_secrets = string
  })
}


# Node selector
variable "node_selector" {
  description = "Node selector for Seq"
  type        = any
  default     = {}
}

# Type of service
variable "service_type" {
  description = "Service type which can be: ClusterIP, NodePort or LoadBalancer"
  type        = string
}

# Working dir
variable "working_dir" {
  description = "Working directory"
  type        = string
  default     = ".."
}

# Enable authentication
variable "authentication" {
  description = "Enables the authentication form"
  type        = bool
  default     = false
}

# SEQ_CACHE_SYSTEMRAMTARGET
variable "system_ram_target" {
  description = "Target RAM size"
  type        = number
}
