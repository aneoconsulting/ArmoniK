# Global variables
variable "namespace" {
  description = "Namespace of ArmoniK storage resources"
  type        = string
}

# Parameters for MongoDB
variable "mongodb" {
  description = "Parameters of MongoDB"
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