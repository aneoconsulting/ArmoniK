# AWS EFS
module "efs" {
  source = "../../../modules/aws/efs"
  tags   = local.tags
  vpc    = var.vpc
  efs    = var.efs
}