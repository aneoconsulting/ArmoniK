# Namespace
variable "namespace" {
  description = "Namespace of ArmoniK monitoring"
  type        = string
}

# Working dir
variable "working_dir" {
  description = "Working directory"
  type        = string
  default     = ".."
}

# Node selector
variable "node_selector" {
  description = "Node selector for Fluent-bit daemonset"
  type        = any
  default     = {}
}

# Cluster info
variable "cluster_info" {
  description = "Cluster info to send logs to CloudWatch Logs"
  type        = object({
    cluster_name              = string
    log_region                = string
    fluent_bit_http_port      = number
    fluent_bit_read_from_head = bool
  })
}

# Cloudwatch container insight
variable "ci_version" {
  description = "Version of cloudwatch container insight"
  type        = string
  default     = "k8s/1.3.8"
}

# Fluent-bit
variable "fluent_bit" {
  description = "Parameters of Fluent bit"
  type        = object({
    image         = string
    tag           = string
  })
}

# CloudWatch infos
variable "cloudwatch_log_group" {
  description = "Infos for CloudWatch log groups"
  type        = object({
    kms_key_id        = string
    retention_in_days = number
    tags              = any
  })
}