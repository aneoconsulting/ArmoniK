resource "aws_cloudwatch_log_group" "log_group" {
  name              = var.name
  kms_key_id        = var.kms_key_id
  retention_in_days = var.retention_in_days
  tags              = var.tags
}