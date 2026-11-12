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
    * workers: the partitions, Spot VMs, then on demand when no Spot capacity is left (on_demand_fallback).
  EOT
  type = object({
    default = optional(object({
      machine_families = optional(list(string), ["n2d", "e2"])
      min_cores        = optional(number, 4)
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
    # KEDA scales the partition from 0 to this many pods
    max_replicas = optional(number, 20)
    # What the partition scales on, and how (autoscaling/README.md). The three laws are computed for every partition
    # (autoscaling/rules.yaml): the dashboard "Bench - autoscaling" shows what the two others would have asked.
    autoscaling = optional(object({
      # queue: the chart's trigger, ceil(queued / 2), read from the metrics exporter.
      # dual:  max(ceil(waiting / queue_target), ceil(processing / utilization)), read from Prometheus.
      # model: the flow model, ceil(max(F, R) + W), read from Prometheus.
      law = optional(string, "queue")
      # chart: the chart's HPA (no limit up, 300 s before a scale-down). fast: the target as it is, 60 s before a
      # scale-down. ramp: fast, but at most twice the pods every 15 s.
      hpa = optional(string, "chart")
      # Parameters of the laws, null for the defaults of the rules (60 s, 0.9, 0 s, 2)
      catchup_seconds = optional(number) # T: time given to absorb the queue
      utilization     = optional(number) # eta: share of its time a pod spends on tasks
      startup_seconds = optional(number) # dt: scale-up decision to ready pod; set, the model predicts the queue then
      queue_target    = optional(number) # q: waiting tasks per pod of the dual law
    }), {})
    # Any other value of the compute-plane chart for this partition, merged last by Helm over the above and the
    # partitionCommon of values/armonik.yaml: agent resources, requests apart from limits, a fixed replicas count...
    values = optional(any, {})
  }))
  default  = {}
  nullable = false

  validation {
    condition     = alltrue([for name in keys(var.partitions) : can(regex("^[a-z0-9]+$", name))])
    error_message = "Partition names must be lowercase alphanumeric: no dash (KEDA metric names)."
  }

  validation {
    condition     = alltrue([for p in values(var.partitions) : contains(["queue", "dual", "model"], p.autoscaling.law)])
    error_message = "autoscaling.law must be queue, dual or model."
  }

  validation {
    condition     = alltrue([for p in values(var.partitions) : contains(["chart", "fast", "ramp"], p.autoscaling.hpa)])
    error_message = "autoscaling.hpa must be chart, fast or ramp."
  }

  validation {
    condition = alltrue([for p in values(var.partitions) :
      coalesce(p.autoscaling.catchup_seconds, 1) > 0 && coalesce(p.autoscaling.queue_target, 1) > 0 &&
      coalesce(p.autoscaling.utilization, 1) > 0 && coalesce(p.autoscaling.utilization, 1) <= 1 &&
      coalesce(p.autoscaling.startup_seconds, 0) >= 0
    ])
    error_message = "autoscaling: catchup_seconds and queue_target must be positive, utilization in ]0, 1], startup_seconds not negative."
  }
}

variable "database" {
  description = <<-EOT
    Cloud SQL instance of the table storage.
    * edition: ENTERPRISE, or ENTERPRISE_PLUS (newer machines, data cache, managed connection pooling).
    * tier: db-custom-<vCPUs>-<memory in MB> in ENTERPRISE, db-perf-optimized-N-<vCPUs> in ENTERPRISE_PLUS.
    * availability_type: ZONAL, or REGIONAL for a standby with automatic failover (twice the price).
    * disk_size: initial size in GB, grown automatically (never shrinks).
    * flags: PostgreSQL flags, over the defaults of the module (logical decoding, max_connections = 500).
    * data_cache: local SSD read cache (ENTERPRISE_PLUS).
    * pooling: Core connects through the managed connection poolers (ENTERPRISE_PLUS), on their port, with their
      flags (pooling_flags). Turning it on or off restarts the instance.
  EOT
  type = object({
    edition           = optional(string, "ENTERPRISE")
    tier              = optional(string, "db-custom-2-8192")
    availability_type = optional(string, "ZONAL")
    disk_size         = optional(number, 20)
    flags             = optional(map(string), {})
    data_cache        = optional(bool, false)
    pooling           = optional(bool, false)
    pooling_flags     = optional(map(string), {})
  })
  default  = {}
  nullable = false
}
