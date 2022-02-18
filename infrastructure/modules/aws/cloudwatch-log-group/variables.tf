# Tags
variable "tags" {
  description = "Tags for resource"
  type        = any
  default     = {}
}

# Name
variable "name" {
  description = "Name of group log"
  type        = string
}

# KMS to encrypt ECR repositories
variable "kms_key_id" {
  description = "KMS to encrypt ECR repositories"
  type        = string
  default     = ""
}

# Retention in days
variable "retention_in_days" {
  description = "Retion in days of logs"
  type        = number
}