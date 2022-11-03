output "id" {
  description = "EFS id"
  value       = aws_efs_file_system.efs.id
}

output "kms_key_id" {
  description = "KMS used to encrypt EFS"
  value       = aws_efs_file_system.efs.kms_key_id
}