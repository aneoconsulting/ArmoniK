# Tags
variable "tags" {
  description = "Tags for resource"
  type        = any
  default     = {}
}

# S3 parameters
variable "name" {
  description = "S3 Service parameters"
  type        = string
  default     = "armonik-s3"
}

variable "kms_key_id" {
  description = "AWS KSM"
  type        = string
}