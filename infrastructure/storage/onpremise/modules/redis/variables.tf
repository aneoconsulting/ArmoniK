# Global variables
variable "namespace" {
  description = "Namespace of ArmoniK storage resources"
  type        = string
}

# Parameters for Redis
variable "redis" {
  description = "Parameters of Redis"
  type        = object({
    replicas = number
    port     = number
  })
}

# Kubernetes secrets for Redis
variable "kubernetes_secret" {
  description = "Secret for Redis created in Kubernetes"
  type = string
}