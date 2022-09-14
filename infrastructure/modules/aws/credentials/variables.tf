# Tags
variable "tags" {
  description = "Tags for resource"
  type        = any
}

# Region
variable "region" {
  description = "Region"
  type        = string
}

# KMS to encrypt credentials
variable "kms_key_id" {
  description = "KMS to encrypt the file of credentials"
  type        = string
}

# Resource name
variable "resource_name" {
  description = "Resource name for which the credentials are created"
  type        = string
}

# Path to directory
variable "directory_path" {
  description = "Path to directory where to save the encrypted file of credentials"
  type        = string
  default     = "./generated/credentials"
}

# User credentials
variable "user" {
  description = "User credentials"
  type = object({
    username = string
    password = string
  })
}
