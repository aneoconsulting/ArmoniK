
# Namespace
variable "namespace" {
  description = "Namespace for Chaos Mesh"
  type        = string
}

variable "service_type" {
  description = "service type : ClusterIP,LoadBalancer,NodePort"
  type        = string
}

variable "node_selector" {
  description = "node selector : {}"
  type        = any
}

# Docker image
variable "docker_image" {
  description = "Docker image for Chaos Mesh"
  type = object({
    chaosmesh = object({
      image = string
      tag   = string
    })
    chaosdaemon = object({
      image = string
      tag   = string
    })
    chaosdashboard = object({
      image = string
      tag   = string
    })
  })
}

# Repository of Chaos Mesh helm chart
variable "helm_chart_repository" {
  description = "Path to helm chart repository for Chaos Mesh"
  type        = string
}

# Version of helm chart
variable "helm_chart_version" {
  description = "Version of chart helm for Chaos Mesh"
  type        = string
}

