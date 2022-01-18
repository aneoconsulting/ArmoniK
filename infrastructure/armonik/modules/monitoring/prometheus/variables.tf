# Namespace
variable "namespace" {
  description = "Namespace of ArmoniK monitoring"
  type        = string
}

# Parameters for prometheus
variable "prometheus" {
  description = "Parameters of prometheus"
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
      name        = "prometheus"
      port        = 9090
      target_port = 9090
      protocol    = "TCP"
    }
  }
}