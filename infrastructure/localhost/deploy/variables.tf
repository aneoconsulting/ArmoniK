#Global variables
variable "namespace" {
  description = "Namespace of ArmoniK resources"
  type        = string
  default     = "armonik"
}

variable "k8s_config_path" {
  description = "Path pf the configuration file of K8s"
  type        = string
  default     = "~/.kube/config"
}

variable "k8s_config_context" {
  description = "Context of K8s"
  type        = string
  default     = "default"
}

# Parameters for object storage
variable "object_storage" {
  description = "Parameters of object storage of ArmoniK"
  type        = object({
    replicas     = number,
    port         = number,
    certificates = map(string),
    secret       = string
  })
  default     = ({
    replicas     = 1,
    port         = 6379,
    certificates = {
      cert_file    = "cert.crt",
      key_file     = "cert.key",
      ca_cert_file = "ca.crt"
    },
    secret       = "object-storage-secret"
  })
}