# Global variables
variable "namespace" {
  description = "Namespace of ArmoniK storage resources"
  type        = string
}

# Parameters for minio
variable "minioconfig" {
  description = "Parameters of S3 payload storage"
  type = object({
    image         = string
    tag           = string
    host          = string
    port          = string
    login         = string
    password      = string
    bucket_name   = string
    node_selector = any
  })
}
