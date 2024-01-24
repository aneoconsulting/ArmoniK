# Region
variable "region" {
  description = "GCP region where the infrastructure will be deployed"
  type        = string
  default     = "europe-west1"
}

# GCP project
variable "project" {
  description = "GCP project name"
  type        = string
}

# SUFFIX
variable "suffix" {
  description = "To suffix the GCP resources"
  type        = string
  default     = ""
}

# labels
variable "labels" {
  description = "Tags for GCP resources"
  type        = any
  default     = {}
}

# KMS key name to encrypt/decrypt resources
variable "kms" {
  description = "Cloud KMS used to encrypt/decrypt resources."
  type = object({
    key_ring   = string
    crypto_key = string
  })
  default = {
    key_ring   = "armonik-europe-west1"
    crypto_key = "armonik-europe-west1"
  }
}

# VPC infos
variable "vpc" {
  description = "GCP VPC info"
  type        = any
  default     = {}
}

# Kubeconfig file path
variable "kubeconfig_file" {
  description = "Kubeconfig file path"
  type        = string
  default     = "generated/kubeconfig"
}

# GCP Kubernetes cluster
variable "gke" {
  description = "GKE cluster configuration"
  type = object({
    enable_public_gke_access = optional(bool, true)
    enable_gke_autopilot     = optional(bool, false)
    kubeconfig_file          = optional(string, "generated/kubeconfig")
    node_pools_labels        = optional(map(map(string)), null)
    node_pools_taints        = optional(map(list(object({ key = string, value = string, effect = string }))), null)
    node_pools               = optional(list(map(any)), null)
  })
  default = {}
}
