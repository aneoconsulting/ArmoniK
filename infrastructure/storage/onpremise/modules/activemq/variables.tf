# Global variables
variable "namespace" {
  description = "Namespace of ArmoniK storage resources"
  type        = string
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
}
