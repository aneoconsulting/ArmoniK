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
  })
}

# Working dir
variable "working_dir" {
  description = "Working directory"
  type        = string
  default     = "../.."
}