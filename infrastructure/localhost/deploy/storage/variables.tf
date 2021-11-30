variable "namespace" {
  description = "Namespace of ArmoniK resources"
  type        = string
}

# Parameters for object storage
variable "object_storage_replicas" {
  description = "Number of replicas for the object storage"
  type        = number
}

variable "object_storage_port" {
  description = "Port to the object storage"
  type        = number
}

variable "object_storage_certificates" {
  description = "TLS certificates for object storage"
  type        = map(string)
}

variable "object_storage_secret_name" {
  description = "Kubernetes secret for object storage"
  type        = string
}