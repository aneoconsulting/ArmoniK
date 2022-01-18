# Namespace
variable "namespace" {
  description = "Namespace of ArmoniK monitoring"
  type        = string
}

# Parameters for Grafana
variable "grafana" {
  description = "Parameters of Grafana"
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
      name        = "grafana"
      port        = 3000
      target_port = 3000
      protocol    = "TCP"
    }
  }
}