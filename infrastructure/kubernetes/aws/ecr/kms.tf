# KMS
module "kms" {
  count  = (var.kms_key_id == "" ? 1 : 0)
  source = "../../../modules/aws/kms"
  name   = "armonik-ecr-kms-${local.tag}"
}