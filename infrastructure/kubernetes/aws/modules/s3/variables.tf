variable "s3_bucket" {
  description = "AWS S3 bucket"
  type        = object({
    name       = string
    kms_key_id = string
    tags       = object({})
  })
}