# Kubeconfig path
variable "k8s_config_path" {
  description = "Path of the configuration file of K8s"
  type        = string
  default     = "~/.kube/config"
}

# Kubeconfig context
variable "k8s_config_context" {
  description = "Context of K8s"
  type        = string
  default     = "default"
}

variable "armonik_versions" {
  description = "Versions of all the ArmoniK components"
  type        = map(string)
}

variable "armonik_images" {
  description = "image_name names of all the ArmoniK components"
  type        = map(set(string))
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

# Kubernetes namespace
variable "namespace" {
  description = "Kubernetes namespace for ArmoniK"
  type        = string
  default     = "armonik"
}

# List of needed storage
variable "storage_endpoint_url" {
  description = "List of storage needed by ArmoniK"
  type        = any
  default     = {}
}

# Monitoring infos
variable "monitoring" {
  description = "Monitoring infos"
  type = object({
    seq = object({
      enabled                = optional(bool, true)
      image_name             = optional(string, "datalust/seq")
      image_tag              = optional(string)
      port                   = optional(number, 8080)
      image_pull_secrets     = optional(string, "")
      service_type           = optional(string, "ClusterIP")
      node_selector          = optional(map(string), {})
      system_ram_target      = optional(number, 0.2)
      cli_image_name         = optional(string, "datalust/seqcli")
      cli_image_tag          = optional(string)
      cli_image_pull_secrets = optional(string, "")
      retention_in_days      = optional(string, "2d")
    })

    grafana = object({
      enabled            = optional(bool, true)
      image_name         = optional(string, "grafana/grafana")
      image_tag          = optional(string)
      port               = optional(number, 3000)
      image_pull_secrets = optional(string, "")
      service_type       = optional(string, "ClusterIP")
      node_selector      = optional(map(string), {})
    })

    node_exporter = object({
      enabled            = optional(bool, true)
      image_name         = optional(string, "prom/node-exporter")
      image_tag          = optional(string)
      image_pull_secrets = optional(string, "")
      node_selector      = optional(map(string), {})
    })

    prometheus = object({
      image_name         = optional(string, "prom/prometheus")
      image_tag          = optional(string)
      image_pull_secrets = optional(string, "")
      service_type       = optional(string, "ClusterIP")
      node_selector      = optional(map(string), {})
    })

    metrics_exporter = object({
      image_name         = optional(string, "dockerhubaneo/armonik_control_metrics")
      image_tag          = optional(string)
      image_pull_secrets = optional(string, "")
      service_type       = optional(string, "ClusterIP")
      node_selector      = optional(map(string), {})
      extra_conf = optional(map(string), { MongoDB__AllowInsecureTls = "true"
        Serilog__MinimumLevel                  = "Information"
        MongoDB__TableStorage__PollingDelayMin = "00:00:01"
      MongoDB__TableStorage__PollingDelayMax = "00:00:10" })
    })

    partition_metrics_exporter = object({
      image_name         = optional(string, "dockerhubaneo/armonik_control_partition_metrics")
      image_tag          = optional(string)
      image_pull_secrets = optional(string, "")
      service_type       = optional(string, "ClusterIP")
      node_selector      = optional(map(string), {})
      extra_conf = optional(map(string), { MongoDB__AllowInsecureTls = "true"
        Serilog__MinimumLevel                  = "Information"
        MongoDB__TableStorage__PollingDelayMin = "00:00:01"
      MongoDB__TableStorage__PollingDelayMax = "00:00:10" })
    })

    fluent_bit = object({
      image_name                         = optional(string, "fluent/fluent-bit")
      image_tag                          = optional(string)
      image_pull_secrets                 = optional(string, "")
      is_daemonset                       = optional(bool, true)
      http_port                          = optional(number, 2020)
      read_from_head                     = optional(string, "true")
      node_selector                      = optional(map(string), {})
      parser                             = optional(string, "docker")
      fluent_bit_state_hostpath          = optional(string, "/var/fluent-bit/state")
      var_lib_docker_containers_hostpath = optional(string, "/var/lib/docker/containers")
      run_log_journal_hostpath           = optional(string, "/run/log/journal")
    })

  })

}

# Enable authentication of seq and grafana
variable "authentication" {
  description = "Enable authentication form in seq and grafana"
  type        = bool
  default     = false
}
