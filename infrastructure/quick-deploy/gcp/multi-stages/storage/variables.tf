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

# GKE infos
variable "gke" {
  description = "GKE cluster infos"
  type        = any
  default     = {}
}

# GAR infos
variable "gar" {
  description = "GAR infos"
  type        = any
  default     = {}
}

# Kubernetes namespace
variable "namespace" {
  description = "Kubernetes namespace for ArmoniK"
  type        = string
  default     = "armonik"
}

# Parameters for MongoDB
variable "mongodb" {
  description = "Parameters of MongoDB"
  type = object({
    image_name      = optional(string, "mongo")
    image_tag       = optional(string, "6.0.7")
    node_selector   = optional(any, {})
    pull_secrets    = optional(string, "")
    replicas_number = optional(number, 1)
  })
  default = {}
}

# GCP Memorystore for Redis
variable "memorystore" {
  description = "Configuration of GCP Memorystore for Redis"
  type = object({
    memory_size_gb     = number
    auth_enabled       = optional(bool, true)
    connect_mode       = optional(string, "DIRECT_PEERING") # or PRIVATE_SERVICE_ACCESS
    display_name       = optional(string, "armonik-redis")
    locations          = optional(list(string), [])
    redis_configs      = optional(map(string), null)
    reserved_ip_range  = optional(string, null)
    persistence_config = optional(map(string), null)
    maintenance_policy = optional(object({
      day        = optional(string),
      start_time = optional(map(string))
    }), null)
    redis_version           = string
    tier                    = optional(string, "BASIC")
    transit_encryption_mode = optional(string, "SERVER_AUTHENTICATION")
    replica_count           = optional(number, 1)
    read_replicas_mode      = optional(string, "READ_REPLICAS_DISABLED")
    secondary_ip_range      = optional(string, "")
    customer_managed_key    = optional(string, null)
  })
  default = null
}

# GCS for object storage of payloads
variable "gcs_os" {
  description = "Use GCS as object storage"
  type        = any
  default     = null
}