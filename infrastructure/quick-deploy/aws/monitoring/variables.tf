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

# Node selector
variable "node_selector" {
  description = "Node selector for Seq"
  type        = any
  default     = {}
}

# EKS info
variable "eks" {
  description = "EKS info"
  type        = any
}

# Monitoring infos
variable "monitoring" {
  description = "Monitoring infos"
  type        = object({
    seq        = object({
      image        = string
      tag          = string
      service_type = string
      use          = bool
    })
    grafana    = object({
      image        = string
      tag          = string
      service_type = string
      use          = bool
    })
    prometheus = object({
      image         = string
      tag           = string
      service_type  = string
      use           = bool
      node_exporter = object({
        image = string
        tag   = string
      })
    })
    /*cloudwatch = object({
      use                       = bool
      fluent_bit_http_port      = number
      fluent_bit_read_from_head = bool
      ci_version                = string
      kms_key_id                = string
      retention_in_days         = number
      fluent_bit                = object({
        image = string
        tag   = string
      })
    })*/
  })
}