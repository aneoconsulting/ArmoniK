# Availability zones
data "aws_availability_zones" "available" {}

# VPC
module "vpc" {
  source                                          = "terraform-aws-modules/vpc/aws"
  version                                         = "3.11.1"
  name                                            = var.name
  cidr                                            = var.vpc.main_cidr_block
  secondary_cidr_blocks                           = var.vpc.pod_cidr_block_private
  azs                                             = data.aws_availability_zones.available.names
  private_subnets                                 = concat(var.vpc.private_subnets, var.vpc.pod_cidr_block_private)
  public_subnets                                  = (var.vpc.enable_private_subnet ? [] : var.vpc.public_subnets)
  enable_nat_gateway                              = !var.vpc.enable_nat_gateway
  single_nat_gateway                              = !var.vpc.single_nat_gateway
  # required for private endpoint
  enable_dns_hostnames                            = true
  enable_dns_support                              = true
  enable_flow_log                                 = true
  create_flow_log_cloudwatch_iam_role             = true
  create_flow_log_cloudwatch_log_group            = true
  flow_log_cloudwatch_log_group_kms_key_id        = var.vpc.flow_log_cloudwatch_log_group_kms_key_id
  flow_log_cloudwatch_log_group_retention_in_days = var.vpc.flow_log_cloudwatch_log_group_retention_in_days
  tags                                            = merge({
    "kubernetes.io/cluster/${var.vpc.cluster_name}" = "shared"
  }, local.tags)
  public_subnet_tags                              = {
    "kubernetes.io/cluster/${var.vpc.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                        = "1"
    Tier                                            = "Public"
  }
  private_subnet_tags                             = {
    "kubernetes.io/cluster/${var.vpc.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"               = "1"
    Tier                                            = "Private"
  }
}