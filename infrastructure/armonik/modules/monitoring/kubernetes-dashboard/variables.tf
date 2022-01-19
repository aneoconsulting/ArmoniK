# Namespace
variable "namespace" {
  description = "Namespace of ArmoniK monitoring"
  type        = string
}

# Parameters for Kubernetes dashboard
variable "kubernetes_dashboard" {
  description = "Parameters of Kubernetes dashboard"
  type        = object({
    replicas = number
    port     = object({
      name        = string
      port        = number
      target_port = number
      protocol    = string
    })
  })
  default     = {
    replicas = 1
    port     = {
      name        = "dashboard"
      port        = 443
      target_port = 8443
      protocol    = "TCP"
    }
  }
}

# Parameters for dashboard metrics scraper
variable "dashboard_metrics_scraper" {
  description = "Parameters of dashboard metrics scraper"
  type        = object({
    replicas = number
    port     = object({
      name        = string
      port        = number
      target_port = number
      protocol    = string
    })
  })
  default     = {
    replicas = 1
    port     = {
      name        = "scraper"
      port        = 8000
      target_port = 8000
      protocol    = "TCP"
    }
  }
}