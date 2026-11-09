variable "project" {
  description = "GCP project of the deployment"
  type        = string
}

variable "region" {
  description = "Region of the network, of the pull-through caches and of the object storage bucket"
  type        = string
  default     = "europe-west9"
}

variable "zone" {
  description = "Zone of the cluster, zonal: in the region"
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
  default     = "armonik69"

  # The gke module names the node service account after the first 20 characters
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{0,18}[a-z0-9]$", var.prefix))
    error_message = "prefix must be 2 to 20 lowercase letters, digits or hyphens, start with a letter and not end with a hyphen."
  }
}

variable "system_pool" {
  description = "Static node pool of the pods GKE runs itself (kube-system), which select no ComputeClass. Every other node comes from the ComputeClasses (node_classes)."
  type = object({
    machine_type = optional(string, "e2-standard-2")
    max_count    = optional(number, 2)
  })
  default  = {}
  nullable = false
}

variable "node_classes" {
  description = <<-EOT
    ComputeClasses, whose node pools GKE creates and removes on demand. Machine families in priority order: the
    autoscaler takes the first one with capacity.
    * default: every pod that selects no class (operators, control plane, ingress, monitoring).
    * database: PostgreSQL, on demand, never migrated.
    * workers: the partitions, Spot VMs, then on demand when no Spot capacity is left (on_demand_fallback).
  EOT
  type = object({
    default = optional(object({
      machine_families = optional(list(string), ["n2d", "e2"])
      min_cores        = optional(number, 4)
    }), {})
    database = optional(object({
      machine_families = optional(list(string), ["n2d", "e2"])
      min_cores        = optional(number, 2)
      min_memory_gb    = optional(number, 8)
    }), {})
    workers = optional(object({
      machine_families   = optional(list(string), ["n2d", "c3d", "e2"])
      min_cores          = optional(number, 8)
      on_demand_fallback = optional(bool, true)
    }), {})
  })
  default  = {}
  nullable = false
}

variable "registry_credentials" {
  description = <<-EOT
    Accounts on the upstream registries, against their rate limits on anonymous pulls: a username and a read-only
    token each. Stored in Secret Manager for the pull-through caches, write-only (never in the state); the Docker Hub
    one also pulls the charts. Increment registry_credentials_version to send new tokens.
  EOT
  type = object({
    dockerhub = optional(object({
      username = string
      token    = string
    }))
    ghcr = optional(object({
      username = string
      token    = string
    }))
  })
  default   = {}
  nullable  = false
  sensitive = true
}

variable "registry_credentials_version" {
  description = "Version of the tokens of registry_credentials: increment it after changing them"
  type        = number
  default     = 1
}

variable "ingress_allowed_cidrs" {
  description = "Source CIDRs allowed on the load balancer of the ingress: the ArmoniK API, the GUI, Seq and Grafana have no authentication"
  type        = list(string)
  default     = ["0.0.0.0/0"]

  validation {
    condition     = length(var.ingress_allowed_cidrs) > 0
    error_message = "ingress_allowed_cidrs must not be empty."
  }
}

variable "versions" {
  description = "Chart version and ArmoniK image tags"
  type = object({
    # armonik and armonik-operators, published by the ArmoniK.Infra CI
    armonik = optional(string, "0.17.1")
    core    = optional(string, "0.41.4")
    gui     = optional(string, "0.16.1")
  })
  default  = {}
  nullable = false
}

variable "partitions" {
  description = "Partitions added to the chart's own (default, stream, htcmock); a worker update is a new tag here"
  type = map(object({
    # Image without its tag, registry included (docker.io/<org>/<image>, <region>-docker.pkg.dev/<project>/<repo>/<image>)
    image  = string
    tag    = string
    cpu    = optional(string, "1")
    memory = optional(string, "1Gi")
    # KEDA scales the partition on its queue length, from 0 to this many pods
    max_replicas = optional(number, 20)
  }))
  default  = {}
  nullable = false

  validation {
    condition     = alltrue([for name in keys(var.partitions) : can(regex("^[a-z0-9]+$", name))])
    error_message = "Partition names must be lowercase alphanumeric: no dash (KEDA metric names)."
  }
}
