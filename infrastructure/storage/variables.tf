# Global variables
variable "namespace" {
  description = "Namespace of ArmoniK storage resources"
  type        = string
  default     = "armonik-storage"
}

variable "k8s_config_path" {
  description = "Path of the configuration file of K8s"
  type        = string
  default     = "~/.kube/config"
}

variable "k8s_config_context" {
  description = "Context of K8s"
  type        = string
  default     = "default"
}

# Profile
variable "aws_profile" {
  description = "Profile of AWS credentials to deploy Terraform sources"
  type        = string
  default     = "default"
}

# AWS region
variable "aws_region" {
  description = "AWS region where resources will be created"
  type        = string
  default     = "eu-west-3"
}

# Storage to be created
variable "storage" {
  description = "List of storage for each ArmoniK data to be created."
  type        = list(string)
  default     = ["MongoDB"]
}

# Kubernetes secrets for storage
variable "storage_kubernetes_secrets" {
  description = "List of Kubernetes secrets for the storage to be created"
  type        = object({
    mongodb  = string
    redis    = string
    activemq = string
  })
  default     = {
    mongodb  = ""
    redis    = "redis-storage-secret"
    activemq = "activemq-storage-secret"
  }
}

# MongoDB
variable "mongodb" {
  description = "Parameters of MongoDB"
  type        = object({
    replicas = number
    port     = number
  })
  default     = {
    replicas = 1
    port     = 27017
  }
}

# Parameters for Redis
variable "redis" {
  description = "Parameters of Redis"
  type        = object({
    replicas = number
    port     = number
  })
  default     = {
    replicas = 1
    port     = 6379
  }
}

# Parameters for ActiveMQ
variable "activemq" {
  description = "Parameters of ActiveMQ"
  type        = object({
    replicas = number
    port     = list(object({
      name        = string
      port        = number
      target_port = number
      protocol    = string
    }))
  })
  default     = {
    replicas = 1
    port     = [
      { name = "amqp", port = 5672, target_port = 5672, protocol = "TCP" },
      { name = "dashboard", port = 8161, target_port = 8161, protocol = "TCP" },
      { name = "openwire", port = 61616, target_port = 61616, protocol = "TCP" },
      { name = "stomp", port = 61613, target_port = 61613, protocol = "TCP" },
      { name = "mqtt", port = 1883, target_port = 1883, protocol = "TCP" }
    ]
  }
}

# AWS Elastic Block Store
variable "aws_ebs" {
  description = "AWS EBS for shared storage between pods"
  type        = object({
    availability_zone = string
    size              = number
    encrypted         = bool
    kms_key_id        = string
    tags              = object({})
  })
  default     = {
    availability_zone = "eu-west-3a"
    size              = 5
    encrypted         = true
    kms_key_id        = ""
    tags              = {}
  }
}