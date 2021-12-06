# Global variables
variable "namespace" {
  description = "Namespace of ArmoniK resources"
  type        = string
}

# Parameters for object storage
variable "redis" {
  description = "Parameters of object storage of ArmoniK"
  type        = object({
    replicas = number,
    port     = number,
    secret   = string
  })
}