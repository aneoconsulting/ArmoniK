variable "project" {
  description = "GCP project of the deployment"
  type        = string
}

variable "region" {
  description = "Region of the network and of the object storage bucket"
  type        = string
  default     = "europe-west9"
}

variable "zone" {
  description = "Zone of the cluster, zonal: in the region, and with the machine types of node_pools"
  type        = string
  default     = "europe-west9-a"

  validation {
    condition     = startswith(var.zone, "${var.region}-")
    error_message = "zone must be in region."
  }
}

variable "prefix" {
  description = "Name of the cluster and prefix of every other resource, Pub/Sub topics included"
  type        = string
  default     = "armonik"

  # The gke module names the node service account after the first 20 characters
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{0,18}[a-z0-9]$", var.prefix))
    error_message = "prefix must be 2 to 20 lowercase letters, digits or hyphens, start with a letter and not end with a hyphen."
  }
}

variable "node_pools" {
  description = "Machine type and maximum node count of the system pool (operators, PostgreSQL, control plane, monitoring) and of the compute pool (partitions, from 0)"
  type = object({
    system = optional(object({
      machine_type = optional(string, "e2-standard-4")
      max_count    = optional(number, 3)
    }), {})
    compute = optional(object({
      machine_type = optional(string, "n2d-standard-4")
      max_count    = optional(number, 10)
      spot         = optional(bool, true)
    }), {})
  })
  default  = {}
  nullable = false
}
