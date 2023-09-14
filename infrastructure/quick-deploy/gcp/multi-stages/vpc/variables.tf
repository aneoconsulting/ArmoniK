# SUFFIX
variable "suffix" {
  description = "To suffix the GCP resources"
  type        = string
  default     = ""
}

# GCP region
variable "region" {
  description = "The GCP region used to deploy all resources"
  type        = string
  default     = "europe-west1"
}

# GCP project
variable "project" {
  description = "GCP project name"
  type        = string
}

# VPC and subnets for resources
variable "gke_subnet" {
  description = "GKE subnet"
  type = object({
    name                = optional(string, "gke-subnet")
    nodes_cidr_block    = optional(string, "10.43.0.0/16")
    pods_cidr_block     = optional(string, "172.16.0.0/16")
    services_cidr_block = optional(string, "172.17.17.0/24")
  })
  default = {}
}