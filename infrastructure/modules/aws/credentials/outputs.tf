# credentials info
output "encrypted_file" {
  description = "Path of the encrypted file"
  value       = "${abspath(var.directory_path)}/${var.resource_name}-creds.yaml"
}

# AWS KMS
output "kms_key_id" {
  description = "KMS ARN with which the credentilas are encrypted"
  value       = var.kms_key_id
}

# Username
output "username" {
  description = "Username of the resource"
  value       = local.username
}

# Password
output "password" {
  description = "Password of the resource"
  value       = local.password
  sensitive   = true
}