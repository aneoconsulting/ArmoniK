# Global variables
variable "namespace" {
  description = "Namespace of ArmoniK storage resources"
  type        = string
  default     = "armonik-storage"
}

variable "region" {
  description = "AWS region in which ArmoniK storage resources will be deployed"
  type        = string
  default     = "us-east-1"
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
  })
  default     = {
    replicas = 1
  }
}