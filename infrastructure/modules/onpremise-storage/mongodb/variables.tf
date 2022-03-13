# Global variables
variable "namespace" {
  description = "Namespace of ArmoniK resources"
  type        = string
}

# Parameters for MongoDB
variable "mongodb" {
  description = "Parameters of MongoDB"
  type        = object({
    image              = string
    tag                = string
    node_selector      = any
    image_pull_secrets = string
  })
}

# Working dir
variable "working_dir" {
  description = "Working directory"
  type        = string
  default     = "../.."
}