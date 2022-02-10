# AWS KMS
module "kms" {
  source = "../../../modules/aws/kms"
  name   = "armonik-kms-ecr-${local.tag}-${local.random_string}"
  tags   = local.tags
}

# AWS ECR
module "ecr" {
  source       = "../../../modules/aws/ecr"
  tags         = local.tags
  kms_key_id   = (var.ecr.kms_key_id != "" ? var.ecr.kms_key_id : module.kms.selected.arn)
  repositories = var.ecr.repositories
}