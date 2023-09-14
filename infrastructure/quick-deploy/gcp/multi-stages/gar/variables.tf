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

# List of GAR repositories to create
variable "gar" {
  description = "List of GAR repositories to create"
  type = map(list(object({
    image = string
    tag   = string
  })))
}