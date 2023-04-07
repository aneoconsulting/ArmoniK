# Namespace
variable "namespace" {
  description = "Namespace of ArmoniK monitoring"
  type        = string
}

# Node selector
variable "node_selector" {
  description = "Node selector for Seq"
  type        = any
  default     = {}
}

# Seq
variable "seq" {
  description = "Seq info"
  type        = any
  default     = {}
}

# CloudWatch
variable "cloudwatch" {
  description = "CloudWatch info"
  type        = any
  default     = {}
}

# S3
variable "s3" {
  description = "S3 for logs"
  type        = any
  default     = {}
}

# Fluent-bit
variable "fluent_bit" {
  description = "Parameters of Fluent bit"
  type = object({
    container_name     = string
    image              = string
    tag                = string
    is_daemonset       = bool
    http_server        = string
    http_port          = string
    read_from_head     = string
    read_from_tail     = string
    image_pull_secrets = string
  })
}