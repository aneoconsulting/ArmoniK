# AWS KMS
module "kms" {
  count  = can(coalesce(var.kms_key)) ? 0 : 1
  source = "./generated/infra-modules/security/aws/kms"
  name   = "${local.prefix}-kms"
  tags   = local.tags
}

locals {
  kms_key = try(one(module.kms[*].arn), var.kms_key)
}
