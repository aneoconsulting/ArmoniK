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

# Storage to be created
variable "storage" {
  description = "List of storage for each ArmoniK data to be created."
  type        = list(string)
  default     = ["MongoDB"]
}

# MongoDB
variable "mongodb" {
  description = "Parameters of MongoDB"
  type        = object({
    replicas = number
    port     = number
    image    = string
    tag      = string
    secret   = string
  })
  default     = {
    replicas = 1
    port     = 27017
    image    = "mongo"
    tag      = "4.4.11"
    secret   = "mongodb-storage-secret"
  }
}

# Parameters for Redis
variable "redis" {
  description = "Parameters of Redis"
  type        = object({
    replicas = number
    port     = number
    image    = string
    tag      = string
    secret   = string
  })
  default     = {
    replicas = 1
    port     = 6379
    image    = "redis"
    tag      = "bullseye"
    secret   = "redis-storage-secret"
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
    image    = string
    tag      = string
    secret   = string
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
    image    = "symptoma/activemq"
    tag      = "5.16.3"
    secret   = "activemq-storage-secret"
  }
}