# SUFFIX
variable "suffix" {
  description = "To suffix the GCP resources"
  type        = string
  default     = ""
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

variable "seq" {
  description = "Seq configuration (nullable)"
  type = object({
    image_name        = optional(string, "datalust/seq")
    image_tag         = optional(string, "2023.3")
    port              = optional(number, 8080)
    pull_secrets      = optional(string, "")
    service_type      = optional(string, "ClusterIP")
    node_selector     = optional(any, {})
    system_ram_target = optional(number, 0.2)
    authentication    = optional(bool, false)
    cli_image_name    = optional(string, "datalust/seqcli")
    cli_image_tag     = optional(string, "2023.2")
    cli_pull_secrets  = optional(string, "")
    retention_in_days = optional(string, "2d")
  })
  default = null
}

variable "node_exporter" {
  description = "Node exporter configuration (nullable)"
  type = object({
    image_name    = optional(string, "prom/node-exporter")
    image_tag     = optional(string, "v1.6.0")
    pull_secrets  = optional(string, "")
    service_type  = optional(string, "ClusterIP")
    node_selector = optional(any, {})
  })
  default = null
}

variable "metrics_exporter" {
  description = "Metrics exporter configuration"
  type = object({
    image_name    = optional(string, "dockerhubaneo/armonik_control_metrics")
    image_tag     = optional(string, "0.20.5")
    pull_secrets  = optional(string, "")
    service_type  = optional(string, "ClusterIP")
    node_selector = optional(any, {})
    extra_conf    = optional(map(string), {})
  })
  default = {}
}

variable "partition_metrics_exporter" {
  description = "Partition metrics exporter configuration (nullable)"
  type = object({
    image_name    = optional(string, "dockerhubaneo/armonik_control_partition_metrics")
    image_tag     = optional(string, "0.20.5")
    pull_secrets  = optional(string, "")
    service_type  = optional(string, "ClusterIP")
    node_selector = optional(any, {})
    extra_conf    = optional(map(string), {})
  })
  default = null
}

variable "prometheus" {
  description = "Prometheus configuration"
  type = object({
    image_name    = optional(string, "prom/prometheus")
    image_tag     = optional(string, "v2.45.0")
    pull_secrets  = optional(string, "")
    service_type  = optional(string, "ClusterIP")
    node_selector = optional(any, {})
  })
  default = {}
}

variable "grafana" {
  description = "Grafana configuration (nullable)"
  type = object({
    image_name     = optional(string, "grafana/grafana")
    image_tag      = optional(string, "10.0.2")
    port           = optional(number, 3000)
    pull_secrets   = optional(string, "")
    service_type   = optional(string, "ClusterIP")
    node_selector  = optional(any, {})
    authentication = optional(bool, false)
  })
  default = null
}

variable "fluent_bit" {
  description = "Fluent bit configuration"
  type = object({
    image_name                         = optional(string, "fluent/fluent-bit")
    image_tag                          = optional(string, "2.1.7")
    pull_secrets                       = optional(string, "")
    is_daemonset                       = optional(bool, true)
    http_port                          = optional(number, 2020)
    read_from_head                     = optional(bool, true)
    node_selector                      = optional(any, {})
    parser                             = optional(string, "cri")
    fluent_bit_state_hostpath          = optional(string, "/var/log/fluent-bit/state")
    var_lib_docker_containers_hostpath = optional(string, "/var/log/lib/docker/containers")
    run_log_journal_hostpath           = optional(string, "/var/log/run/log/journal")
  })
  default = {}
}
