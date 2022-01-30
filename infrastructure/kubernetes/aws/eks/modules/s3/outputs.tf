output "selected" {
  description = "AWS S3 bucket"
  value       = module.s3_bucket
}

output "kms_key_id" {
  description = "KMS ARN of AWS S3 bucket"
  value       = var.s3_bucket.kms_key_id
}