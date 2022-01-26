output "selected" {
  value = aws_kms_key.kms
}

output "kms_alias" {
  value = aws_kms_alias.kms_alias
}