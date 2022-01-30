# KMS
module "kms" {
  source = "../../../modules/aws/kms"
  name   = "armonik-eks-kms-${local.tag}"
}