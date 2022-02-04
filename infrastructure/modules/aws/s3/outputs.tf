output "selected" {
  description = "AWS S3 bucket"
  value       = module.s3_bucket
}

output "s3_bucket_name" {
  description = "Name of S3 bucket"
  value       = module.s3_bucket.s3_bucket_id
}

output "kms_key_id" {
  description = "ARN of KMS used for S3"
  value       = var.kms_key_id
}