# AWS EFS
module "efs" {
  source = "../../../modules/aws/efs"
  tags   = local.tags
  vpc = {
    id          = var.vpc.id
    cidr_blocks = var.vpc.cidr_blocks
    subnet_ids  = var.vpc.subnet_ids
  }
  efs = {
    name                            = var.efs.name
    kms_key_id                      = var.efs.kms_key_id
    performance_mode                = var.efs.performance_mode
    throughput_mode                 = var.efs.throughput_mode
    provisioned_throughput_in_mibps = var.efs.provisioned_throughput_in_mibps
    transition_to_ia                = var.efs.transition_to_ia
    access_point                    = var.efs.access_point
  }
}