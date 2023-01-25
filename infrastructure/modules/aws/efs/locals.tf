# Current account
data "aws_caller_identity" "current" {}

# Current AWS region
data "aws_region" "current" {}

data "aws_availability_zones" "az" {
  all_availability_zones = true
}

# Availability zones
data "aws_subnet" "private_subnet" {
  for_each   = toset(var.vpc.cidr_block_private)
  cidr_block = each.key

  # dummy ternary impose dependency on subnets even though depends_on does not work here
  vpc_id = var.vpc.subnet_ids != null ? var.vpc.id : var.vpc.id
}

locals {
  account_id = data.aws_caller_identity.current.id
  region     = data.aws_region.current.name
  tags       = merge(var.tags, { module = "efs" })
  encrypt    = (var.efs.kms_key_id != "" && var.efs.kms_key_id != null)
}
