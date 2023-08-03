# AWS KMS
module "kms" {
  count  = (var.vpc.flow_log_cloudwatch_log_group_kms_key_id == "" ? 1 : 0)
  source = "../generated/infra-modules/utils/aws/kms"
  name   = local.kms_name
  tags   = local.tags
}

# AWS VPC
module "vpc" {
  source                                          = "../generated/infra-modules/networking/aws/vpc"
  name                                            = local.vpc_name
  eks_name                                        = local.cluster_name
  cidr                                            = var.vpc.main_cidr_block
  private_subnets                                 =var.vpc.cidr_block_private
  public_subnets                                  =var.vpc.cidr_block_public
  pod_subnets                                     = var.vpc.pod_cidr_block_private
  flow_log_cloudwatch_log_group_kms_key_id        =  (var.vpc.flow_log_cloudwatch_log_group_kms_key_id != "" ? var.vpc.flow_log_cloudwatch_log_group_kms_key_id : module.kms.0.arn)
  flow_log_cloudwatch_log_group_retention_in_days = var.vpc.flow_log_cloudwatch_log_group_retention_in_days
  tags = local.tags
}
