# AWS KMS
module "kms" {
  count  = (var.ecr.kms_key_id == "" ? 1 : 0)
  source = "../generated/infra-modules/utils/aws/kms"
  name   = local.kms_name
  tags   = local.tags
}

# AWS ECR
module "ecr" {
  source       = "../generated/infra-modules/container-registry/aws/ecr"
  aws_profile  = var.profile
  kms_key_id   = (var.ecr.kms_key_id != "" ? var.ecr.kms_key_id : module.kms.0.arn)
  repositories = local.repositories
  tags         = local.tags
}