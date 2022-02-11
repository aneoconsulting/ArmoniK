output "s3_bucket_name" {
  description = "Name of S3 bucket"
  value       = aws_s3_bucket.s3_bucket.id
}

output "kms_key_id" {
  description = "ARN of KMS used for S3"
  value       = var.s3.kms_key_id
}