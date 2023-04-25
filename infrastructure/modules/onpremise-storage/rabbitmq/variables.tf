# Global variables
variable "namespace" {
  description = "Namespace of ArmoniK storage resources"
  type        = string
}

# Parameters for Rabbitmq
variable "rabbitmq" {
  description = "Parameters of Rabbitmq"
  type = object({
    image              = string
    tag                = string
    node_selector      = any
    image_pull_secrets = string
    protocol           = string
  })
}

# Working dir
variable "working_dir" {
  description = "Working directory"
  type        = string
  default     = "../.."
}
