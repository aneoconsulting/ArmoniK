variable "region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-3"
}

variable "profile" {
  description = "AWS CLI profile, null to use the environment credentials"
  type        = string
  default     = null
}

variable "prefix" {
  description = "Name prefix of every resource of the deployment (cluster, database, bucket, ECR, IAM roles)"
  type        = string

  validation {
    # IAM role names stay under 64 characters: <prefix>-eks-pod-identity-armonik-control-plane
    condition     = can(regex("^[a-z][a-z0-9-]{1,19}$", var.prefix))
    error_message = "prefix must be lowercase alphanumeric with dashes, 2 to 20 characters, starting with a letter."
  }
}

variable "tags" {
  description = "Tags added to every resource"
  type        = map(string)
  default     = {}
}

variable "namespace" {
  description = "Namespace of the armonik release, where Pod Identity binds the ArmoniK service accounts"
  type        = string
  default     = "armonik"
}

variable "operators_namespace" {
  description = "Namespace of the armonik-operators release"
  type        = string
  default     = "armonik-operators"
}

variable "vpc" {
  description = "VPC: three /18 private subnets (nodes and pods) and three /24 public ones (NAT, load balancers)"
  type = object({
    cidr      = optional(string, "10.0.0.0/16")
    flow_logs = optional(bool, false)
  })
  default = {}
}

variable "eks" {
  description = "EKS cluster and its system node group (Karpenter, the load balancer controller, CoreDNS, the CSI controllers)"
  type = object({
    kubernetes_version           = optional(string, "1.35")
    endpoint_public_access_cidrs = optional(list(string), ["0.0.0.0/0"])
    system_instance_types        = optional(list(string), ["t3a.medium"])
    system_node_group_size       = optional(number, 2)
  })
  default = {}
}

variable "node_pools" {
  description = "Karpenter node pools (node_pools of the karpenter module of ArmoniK.Infra). core runs everything but the system and the partitions; the partitions run on workers"
  type = map(object({
    capacity_types       = optional(list(string))
    instance_categories  = optional(list(string))
    min_generation       = optional(number)
    min_cpu              = optional(number)
    architectures        = optional(list(string))
    taint                = optional(bool)
    limits               = optional(map(string))
    consolidation_policy = optional(string)
    consolidate_after    = optional(string)
  }))
  default = {
    # Control plane, ingress, operators, monitoring: on-demand, consolidated when underused
    core = {
      capacity_types = ["on-demand"]
      limits         = { cpu = "64" }
    }
    # Compute plane: spot first, tainted, and never consolidated while a worker runs on the node
    workers = {
      capacity_types       = ["spot", "on-demand"]
      instance_categories  = ["c", "m"]
      taint                = true
      limits               = { cpu = "1000" }
      consolidation_policy = "WhenEmpty"
      consolidate_after    = "1m"
    }
  }

  validation {
    condition     = contains(keys(var.node_pools), "workers")
    error_message = "node_pools needs a workers pool: the partitions run there."
  }
}

variable "object_storage" {
  description = <<-EOT
    Object storage of Core: an S3 general purpose bucket (always created), or an S3 Express One Zone directory bucket.
    * express: Core uses the directory bucket instead.
    * express_zone_id: Availability Zone ID of the directory bucket (euw3-az1 in eu-west-3).
    * pin_to_express_zone: the Karpenter pools start their nodes in that zone only, the lowest latency to the bucket,
      at the cost of the spot capacity of the other zones.
  EOT
  type = object({
    express             = optional(bool, false)
    express_zone_id     = optional(string)
    pin_to_express_zone = optional(bool, false)
  })
  default  = {}
  nullable = false

  validation {
    condition     = !var.object_storage.express || var.object_storage.express_zone_id != null
    error_message = "object_storage.express requires object_storage.express_zone_id."
  }
  validation {
    condition     = !var.object_storage.pin_to_express_zone || var.object_storage.express
    error_message = "object_storage.pin_to_express_zone requires object_storage.express."
  }
}

variable "database" {
  description = "Aurora PostgreSQL cluster (aurora module of ArmoniK.Infra), optionally behind an RDS Proxy"
  type = object({
    engine_version     = optional(string, "18.4")
    instance_class     = optional(string, "db.r8g.large")
    instances          = optional(number, 1)
    io_optimized       = optional(bool, false)
    cluster_parameters = optional(map(string), {})
    # Serverless v2 instead of instance_class, in ACUs (1 ACU: about 2 GiB with the matching CPU)
    serverless = optional(object({
      min_capacity             = optional(number)
      max_capacity             = number
      seconds_until_auto_pause = optional(number)
    }))
    proxy = optional(object({
      enabled                      = optional(bool)
      max_connections_percent      = optional(number)
      max_idle_connections_percent = optional(number)
      connection_borrow_timeout    = optional(number)
      idle_client_timeout          = optional(number)
      session_pinning_filters      = optional(list(string))
      debug_logging                = optional(bool)
    }), {})
  })
  default = {}
}

variable "registry_credentials" {
  description = "Upstream credentials of the ECR pull-through cache, required by AWS for Docker Hub and GitHub"
  type = object({
    docker_hub = object({
      username     = string
      access_token = string
    })
    github = object({
      username     = string
      access_token = string
    })
  })
  ephemeral = true
  sensitive = true
}

variable "registry_credentials_version" {
  description = "Bump to push new registry_credentials, which are write-only and never stored in the state"
  type        = number
  default     = 1
}

variable "ingress_allowed_cidrs" {
  description = "Source CIDRs allowed on the NLB: the ArmoniK API, the GUI, Seq and Grafana have no authentication"
  type        = list(string)

  validation {
    condition     = length(var.ingress_allowed_cidrs) > 0
    error_message = "ingress_allowed_cidrs must not be empty: 0.0.0.0/0 opens the NLB to everyone."
  }
}

variable "versions" {
  description = "Chart versions and ArmoniK image tags"
  type = object({
    # armonik and armonik-operators, published by the ArmoniK.Infra CI: <version>-SNAPSHOT.<n>.sha.<commit> from main,
    # <version>-<branch>.<n>.sha.<commit> from a pull request. This one: Infra #450 (control plane events Deployment)
    # over #447 (external PostgreSQL pooler)
    armonik   = optional(string, "0.18.0-claudeeloquentc.67.sha.55d985bd")
    core      = optional(string, "0.41.5")
    gui       = optional(string, "0.16.1")
    karpenter = optional(string, "1.14.1")
    lbc       = optional(string, "3.5.0")
    cilium    = optional(string, "1.20.4")
    # metrics-server chart (kubernetes-sigs), for the CPU triggers of the control planes
    metrics_server = optional(string, "3.12.2")
  })
  default = {}
}

variable "partitions" {
  description = "Your partitions, beside the chart's htcmock (default and stream are removed in values/armonik.yaml); a worker update is a new tag here"
  type = map(object({
    # Image without its tag, registry included (e.g. the workers_repository output)
    image     = string
    tag       = string
    cpu       = optional(string, "1")
    cpu_limit = optional(string)
    memory    = optional(string, "1Gi")
    # KEDA scales the partition on its queue length, up to this many pods
    max_replicas = optional(number, 50)
    # false keeps one idle pod, so the first tasks skip the pod and node start (1 to 3 min)
    scale_to_zero = optional(bool, true)
    # Scale on armonik:scaler_target instead of the queue length: recording rules of the autoscaling-monitoring chart
    # (rules/autoscaling.rules.yaml) over the exporter counts and the polling agent metrics, read from Prometheus
    promql = optional(bool, false)
    # HPA without rate limits on scale-up, 60 s before removing an idle pod (chart: 300 s), polling every 5 s
    fast_hpa = optional(bool, false)
    # Any other compute-plane value of the partition, YAML, merged last
    values = optional(string, "{}")
  }))
  default = {}

  validation {
    condition     = alltrue([for name in keys(var.partitions) : can(regex("^[a-z0-9]+$", name))])
    error_message = "Partition names must be lowercase alphanumeric: no dash (KEDA metric names)."
  }
}

variable "operators_values" {
  description = "Values documents (YAML text) of the armonik-operators release, merged last"
  type        = list(string)
  default     = []
}

variable "armonik_values" {
  description = "Values documents (YAML text) of the armonik release, merged last, before the values of each partition: the sizing of a stack"
  type        = list(string)
  default     = []
}

variable "bench_monitoring" {
  description = "Deploy the bench monitoring (bench-monitoring.tf): Grafana folder Bench over CloudWatch, postgres_exporter and SQL, S3 request metrics"
  type        = bool
  default     = true
}

variable "autoscaling_monitoring" {
  description = "Deploy the autoscaling-monitoring chart: Karpenter ServiceMonitor, autoscaling recording rules and dashboard (bench/README.md). Required by promql partitions"
  type        = bool
  default     = true
}
