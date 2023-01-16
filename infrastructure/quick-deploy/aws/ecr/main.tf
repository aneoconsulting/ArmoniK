# AWS KMS
module "kms" {
  count  = (var.ecr.kms_key_id == "" ? 1 : 0)
  source = "../../../modules/aws/kms"
  name   = local.kms_name
  tags   = local.tags
}

# AWS ECR
module "ecr" {
  source       = "../../../modules/aws/ecr"
  profile      = var.profile
  tags         = local.tags
  kms_key_id   = (var.ecr.kms_key_id != "" ? var.ecr.kms_key_id : module.kms.0.arn)
  repositories = var.ecr.repositories
}