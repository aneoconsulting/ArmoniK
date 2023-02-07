# Tags
variable "tags" {
  description = "Tags for resource"
  type        = any
  default     = {}
}

# Kubernetes namespace
variable "namespace" {
  description = "Kubernetes namespace for ArmoniK"
  type        = string
}

# MQ name
variable "name" {
  description = "AWS MQ service name"
  type        = string
  default     = "armonik-mq"
}

# VPC infos
variable "vpc" {
  description = "AWS VPC info"
  type = object({
    id          = string
    cidr_blocks = list(string)
    subnet_ids  = list(string)
  })
}

# User credentials
variable "user" {
  description = "User credentials"
  type = object({
    password = string
    username = string
  })
}

# MQ parameters
variable "mq" {
  description = "MQ Service parameters"
  type = object({
    engine_type             = string
    engine_version          = string
    host_instance_type      = string
    apply_immediately       = bool
    deployment_mode         = string
    storage_type            = string
    authentication_strategy = string
    publicly_accessible     = bool
    kms_key_id              = string
  })
}