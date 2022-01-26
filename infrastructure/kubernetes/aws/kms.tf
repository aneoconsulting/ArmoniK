# KMS
module "kms" {
  source = "../../modules/aws/kms"
  name   = "armonik-kms-${local.tag}"
}