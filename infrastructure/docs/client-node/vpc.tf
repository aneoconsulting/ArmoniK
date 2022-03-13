module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  version = "3.12.0"
  name = "client-vpc"
  cidr = var.vpc_cidr_block
  azs             = ["${var.region}a", "${var.region}b", "${var.region}c"]
  private_subnets = var.private_subnet_cidr_block
  public_subnets  = var.public_subnet_cidr_block
  enable_nat_gateway = true
  enable_vpn_gateway = true
}
