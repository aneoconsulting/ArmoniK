# Global variables
variable "namespace" {
  description = "Namespace of ArmoniK resources"
  type        = string
}

# Parameters for Redis
variable "redis" {
  description = "Parameters of Redis of ArmoniK"
  type        = object({
    replicas = number,
    port     = number,
    secret   = string
  })
}