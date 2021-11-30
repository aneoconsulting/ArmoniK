variable "namespace" {
  description = "Namespace of ArmoniK resources"
  type        = string
  default     = "armonik"
}

# Parameters for object storage
variable "object_storage_replicas" {
  description = "Number of replicas for the object storage"
  type        = number
  default     = 1
}

variable "object_storage_port" {
  description = "Port to the object storage"
  type        = number
  default     = 6379
}

variable "object_storage_certificates" {
  description = "TLS certificates for object storage"
  type        = map(string)
  default     = { cert_file = "cert.crt", key_file = "cert.key", ca_cert_file = "ca.crt" }
}

variable "object_storage_secret_name" {
  description = "Kubernetes secret for object storage"
  type        = string
  default     = "object-storage-secret"
}
