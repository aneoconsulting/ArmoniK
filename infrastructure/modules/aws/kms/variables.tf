# Tags
variable "tags" {
  description = "Tags for resource"
  type        = any
  default     = {}
}

# KMS parameters
variable "name" {
  description = "AWS Key Management Service parameters"
  type        = string
  default     = "armonik-kms"
}
