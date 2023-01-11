# AWS VPC
module "vpc" {
  source = "../../../modules/aws/vpc"
  tags   = local.tags
  name   = "${local.prefix}-vpc"
  vpc = {
    cluster_name                                    = "${local.prefix}-eks"
    private_subnets                                 = var.vpc.cidr_block_private
    public_subnets                                  = var.vpc.cidr_block_public
    main_cidr_block                                 = var.vpc.main_cidr_block
    pod_cidr_block_private                          = var.vpc.pod_cidr_block_private
    enable_private_subnet                           = var.vpc.enable_private_subnet
    enable_nat_gateway                              = var.vpc.enable_private_subnet
    single_nat_gateway                              = var.vpc.enable_private_subnet
    flow_log_cloudwatch_log_group_retention_in_days = var.vpc.flow_log_cloudwatch_log_group_retention_in_days
    flow_log_cloudwatch_log_group_kms_key_id        = local.kms_key
    peering                                         = var.vpc.peering
  }
}

locals {
  vpc = {
    id = module.vpc.id
    cidr_block_private = var.vpc.cidr_block_private
    cidr_blocks = concat([module.vpc.cidr_block], module.vpc.pod_cidr_block_private)
    subnet_ids = [ for i in range(length(var.vpc.cidr_block_private)): try(module.vpc.private_subnet_ids[i], null) ]
  }
}
