# KMS
module "kms" {
  source = "../../../modules/aws/kms"
  name   = "armonik-ecr-kms-${local.tag}"
}