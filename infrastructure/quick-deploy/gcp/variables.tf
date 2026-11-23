variable "prefix" {
  description = "Prefix used to name all the resources"
  type        = string
  default     = null # random
}

variable "region" {
  description = "The GCP region used to deploy all resources"
  type        = string
  default     = "europe-west1"
}

variable "project" {
  description = "GCP project name"
  type        = string
}

variable "labels" {
  description = "Labels for GCP resources"
  type        = map(string)
  default     = {}
}

variable "kms" {
  description = "Cloud KMS used to encrypt/decrypt resources."
  type = object({
    key_ring   = string
    crypto_key = string
  })
}

variable "subnets" {
  description = "A map of subnets inside the VPC. Each subnet object has a CIDR block, a region, and a boolean set to true if the subnet is public, or false if the subnet is private"
  type = map(object({
    cidr_block    = optional(string)
    public_access = optional(bool)
  }))
  default = null
}

variable "gke" {
  description = "GKE cluster configuration"
  type = object({
    subnet = optional(object({
      name                = optional(string, "gke-subnet")
      nodes_cidr_block    = optional(string, "10.43.0.0/16")
      pods_cidr_block     = optional(string, "172.16.0.0/16")
      services_cidr_block = optional(string, "172.17.17.0/24")
    }), {})
    namespace           = optional(string, "armonik")
    generate_kubeconfig = optional(bool, true)
    kubeconfig_file     = optional(string, "generated/kubeconfig")
    # Lets Terraform and kubectl reach the DNS endpoint of the control plane from outside the VPC, authenticated by IAM
    enable_public_gke_access = optional(bool, true)
    regional                 = optional(bool, true)
    zones                    = optional(list(string), [])
    # Node pools keyed by name, see the node_pools variable of the gke module of ArmoniK.Infra
    node_pools = optional(any)
  })
  default = {}
}

variable "chaos_mesh" {
  description = "Chaos Mesh configuration"
  type = object({
    namespace                 = optional(string, "chaos-mesh")
    chaosmesh_image_name      = optional(string, "ghcr.io/chaos-mesh/chaos-mesh"),
    chaosmesh_image_tag       = optional(string),
    chaosdaemon_image_name    = optional(string, "ghcr.io/chaos-mesh/chaos-daemon"),
    chaosdaemon_image_tag     = optional(string),
    chaosdashboard_image_name = optional(string, "ghcr.io/chaos-mesh/chaos-dashboard"),
    chaosdashboard_image_tag  = optional(string),
    helm_chart_repository     = optional(string)
    helm_chart_version        = optional(string)
    service_type              = optional(string, "LoadBalancer")
    node_selector             = optional(any, {})
    endpoint_url              = optional(string)
  })
  default = null
}

variable "memorystore" {
  description = "Configuration of GCP Memorystore for Valkey, see the valkey module of ArmoniK.Infra"
  type = object({
    node_type               = optional(string)
    replica_count           = optional(number)
    engine_version          = optional(string)
    engine_configs          = optional(map(string), {})
    transit_encryption_mode = optional(string, "SERVER_AUTHENTICATION")
    zone_distribution = optional(object({
      mode = string
      zone = optional(string)
    }))
    persistence = optional(object({
      mode                    = string
      rdb_snapshot_period     = optional(string)
      rdb_snapshot_start_time = optional(string)
      aof_append_fsync        = optional(string)
    }))
    maintenance_window = optional(object({
      day     = string
      hours   = number
      minutes = optional(number, 0)
    }))
  })
  default = null
}

variable "armonik_images" {
  description = "Image names of all the ArmoniK components"
  type = object({
    infra         = set(string)
    infra_plugins = set(string)
    core          = set(string)
    api           = set(string)
    gui           = set(string)
    extcsharp     = set(string)
    samples       = set(string)
  })
}

variable "armonik_versions" {
  description = "Versions of all the ArmoniK components"
  type = object({
    infra         = string
    infra_plugins = string
    core          = string
    api           = string
    gui           = string
    extcsharp     = string
    samples       = string
  })
}

variable "image_tags" {
  description = "Tags of images used"
  type        = map(string)
}

variable "helm_charts" {
  description = "Versions of helm charts repositories"
  type = map(object({
    repository = string
    version    = string
  }))
}

variable "logging_level" {
  description = "Logging level in ArmoniK"
  type        = string
  default     = "Information"
}

variable "activemq" {
  description = "Queue of Core: ActiveMQ in the cluster, instead of Pub/Sub"
  type        = bool
  default     = false
  nullable    = false
}

variable "operators_namespace" {
  description = "Namespace of the armonik-operators release (External Secrets, KEDA, cert-manager, kube-prometheus-stack, CloudNativePG)"
  type        = string
  default     = "armonik-operators"
  nullable    = false
}

variable "partitions" {
  description = "Partitions added to the chart's own (default, stream, htcmock), see the partitions variable of the armonik-charts module of ArmoniK.Infra"
  type        = any
  default     = {}
  nullable    = false
}

variable "armonik_values" {
  description = "Values of the armonik chart, as YAML text, merged last"
  type        = string
  default     = "{}"
  nullable    = false
}

variable "operators_values" {
  description = "Values of the armonik-operators chart, as YAML text, merged last"
  type        = string
  default     = "{}"
  nullable    = false
}
