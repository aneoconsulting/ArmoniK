# Availability zones
data "aws_availability_zones" "available" {}

module "vpc" {
  source                                          = "terraform-aws-modules/vpc/aws"
  version                                         = "3.11.3"
  name                                            = "${var.tag}-${var.vpc_parameters.name}"
  cidr                                            = var.vpc_parameters.cidr
  azs                                             = data.aws_availability_zones.available.names
  private_subnets                                 = var.vpc_parameters.private_subnets_cidr
  public_subnets                                  = var.vpc_parameters.public_subnets_cidr
  enable_nat_gateway                              = !var.vpc_parameters.enable_private_subnet
  single_nat_gateway                              = !var.vpc_parameters.enable_private_subnet
  # required for private endpoint
  enable_dns_hostnames                            = true
  enable_dns_support                              = true
  enable_flow_log                                 = true
  create_flow_log_cloudwatch_iam_role             = true
  create_flow_log_cloudwatch_log_group            = true
  flow_log_cloudwatch_log_group_kms_key_id        = var.vpc_parameters.flow_log_cloudwatch_log_group_kms_key_id
  flow_log_cloudwatch_log_group_retention_in_days = var.vpc_parameters.flow_log_cloudwatch_log_group_retention_in_days

  tags = merge({ "kubernetes.io/cluster/${var.cluster_name}" = "shared" }, local.tags)

  public_subnet_tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                    = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"           = "1"
  }
}
