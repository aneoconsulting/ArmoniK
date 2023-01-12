# Global variables
variable "namespace" {
  description = "Namespace of ArmoniK storage resources"
  type        = string
}

# Parameters for minio
variable "minio" {
  description = "Parameters of S3 payload storage"
  type = object({
    image              = string
    tag                = string
    node_selector      = any
  })
}

