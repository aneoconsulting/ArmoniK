# Global variables
variable "namespace" {
  description = "Namespace of ArmoniK storage resources"
  type        = string
}

# Parameters for MongoDB
variable "mongodb" {
  description = "Parameters of MongoDB"
  type        = object({
    replicas = number
    port     = number
  })
}

# Kubernetes secrets for MongoDB
variable "kubernetes_secret" {
  description = "Secret for MongoDB created in Kubernetes"
  type = string
}