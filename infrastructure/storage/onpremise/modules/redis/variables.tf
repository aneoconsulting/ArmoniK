# Global variables
variable "namespace" {
  description = "Namespace of ArmoniK storage resources"
  type        = string
}

# Parameters for Redis
variable "redis" {
  description = "Parameters of Redis"
  type        = object({
    replicas      = number
    port          = number
    image         = string
    tag           = string
    secret        = string
    node_selector = any
    credentials_user_secret        = string
    credentials_user_type          = string
    credentials_user_key_username  = string
    credentials_user_key_password  = string
    credentials_user_namespace     = string
  })
}

# Working dir
variable "working_dir" {
  description = "Working directory"
  type        = string
  default     = "../.."
}