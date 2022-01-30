# create ECR repositories
resource "aws_ecr_repository" "ecr" {
  count = length(var.repositories)
  name  = var.repositories[count.index].name
  encryption_configuration {
    encryption_type = "KMS"
    kms_key         = (var.kms_key_id != "" ? var.kms_key_id : module.kms.selected.arn)
  }
  tags  = merge(local.tags, { resource = "ECR" })
}