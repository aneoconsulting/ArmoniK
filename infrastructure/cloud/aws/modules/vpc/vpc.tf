# Availability zones
data "aws_availability_zones" "available" {}

module "vpc" {
  source               = "terraform-aws-modules/vpc/aws"
  version              = "3.11.3"
  name                 = "${var.tag}-armonik-${var.vpc.name}"
  cidr                 = var.vpc.cidr
  azs                  = data.aws_availability_zones.available.names
  private_subnets      = var.vpc.private_subnets_cidr
  public_subnets       = var.vpc.public_subnets_cidr
  enable_nat_gateway   = !var.vpc.enable_private_subnet
  single_nat_gateway   = !var.vpc.enable_private_subnet
  # required for private endpoint
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }

  public_subnet_tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                      = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"             = "1"
  }
}
