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

variable "s3" {
  description = "Parameters of S3"
  type = object({
    policy                                = string
    attach_policy                         = bool
    attach_deny_insecure_transport_policy = bool
    attach_require_latest_tls_policy      = bool
    attach_public_policy                  = bool
    block_public_acls                     = bool
    block_public_policy                   = bool
    ignore_public_acls                    = bool
    restrict_public_buckets               = bool
    kms_key_id                            = string
    sse_algorithm                         = string
    ownership                             = string
    versioning                            = string
  })
  validation {
    condition     = contains(["BucketOwnerPreferred", "ObjectWriter"], var.s3.ownership)
    error_message = "Valid values for \"ownership\": \"BucketOwnerPreferred\" | \"ObjectWriter\"."
  }
  validation {
    condition     = contains(["Enabled", "Suspended", "Disabled"], var.s3.versioning)
    error_message = "Valid values for \"versioning\": \"Enabled\" | \"Suspended\" | \"Disabled\"."
  }
}
