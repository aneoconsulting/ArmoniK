# Global variables
variable "namespace" {
  description = "Namespace of ArmoniK storage resources"
  type        = string
}

# Parameters for ActiveMQ
variable "activemq" {
  description = "Parameters of ActiveMQ"
  type        = object({
    replicas      = number
    port          = list(object({
      name        = string
      port        = number
      target_port = number
      protocol    = string
    }))
    image         = string
    tag           = string
    secret        = string
    node_selector = any
    credentials_user_secret        = string
    credentials_user_type          = string
    credentials_user_key_username  = string
    credentials_user_key_password  = string
    credentials_user_namespace     = string
    credentials_admin_secret       = string
    credentials_admin_type         = string
    credentials_admin_key_username = string
    credentials_admin_key_password = string
    credentials_admin_namespace    = string
  })
}

# Working dir
variable "working_dir" {
  description = "Working directory"
  type        = string
  default     = "../.."
}
