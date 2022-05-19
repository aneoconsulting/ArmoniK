# Profile
variable "profile" {
  description = "Profile of AWS credentials to deploy Terraform sources"
  type        = string
  default     = "default"
}

# Region
variable "region" {
  description = "AWS region where the infrastructure will be deployed"
  type        = string
  default     = "eu-west-3"
}

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

# SUFFIX
variable "suffix" {
  description = "To suffix the AWS resources"
  type        = string
  default     = ""
}

# AWS TAGs
variable "tags" {
  description = "Tags for AWS resources"
  type        = any
  default     = {}
}

# Kubernetes namespace
variable "namespace" {
  description = "Kubernetes namespace for ArmoniK"
  type        = string
  default     = "armonik"
}

# EKS info
variable "eks" {
  description = "EKS info"
  type        = any
  default     = {}
}

# List of needed storage
variable "storage_endpoint_url" {
  description = "List of storage needed by ArmoniK"
  type        = any
  default     = {}
}

# Logging level
variable "logging_level" {
  description = "Logging level in ArmoniK"
  type        = string
  default     = "Information"
}

# Monitoring infos
variable "monitoring" {
  description = "Monitoring infos"
  type        = object({
    seq                = object({
      enabled            = bool
      image              = string
      tag                = string
      port               = number
      image_pull_secrets = string
      service_type       = string
      node_selector      = any
    })
    grafana            = object({
      enabled            = bool
      image              = string
      tag                = string
      port               = number
      image_pull_secrets = string
      service_type       = string
      node_selector      = any
    })
    node_exporter      = object({
      enabled            = bool
      image              = string
      tag                = string
      image_pull_secrets = string
      node_selector      = any
    })
    prometheus         = object({
      image              = string
      tag                = string
      image_pull_secrets = string
      service_type       = string
      node_selector      = any
    })
    metrics_exporter   = object({
      image              = string
      tag                = string
      image_pull_secrets = string
      service_type       = string
      node_selector      = any
    })
    cloudwatch         = object({
      enabled           = bool
      kms_key_id        = string
      retention_in_days = number
    })
    fluent_bit         = object({
      image              = string
      tag                = string
      image_pull_secrets = string
      is_daemonset       = bool
      http_port          = number
      read_from_head     = string
      node_selector      = any
    })
  })
}