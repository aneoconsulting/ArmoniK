# Current account
data "aws_caller_identity" "current" {}

# Current AWS region
data "aws_region" "current" {}

# Availability zones
data "aws_subnet" "private_subnet" {
  for_each = toset(var.vpc.subnet_ids)
  id       = each.key
}

locals {
  account_id = data.aws_caller_identity.current.id
  region     = data.aws_region.current.name
  tags       = merge(var.tags, { module = "efs" })
  encrypt    = (var.efs.kms_key_id != "" && var.efs.kms_key_id != null)
  subnet     = { for subnet in data.aws_subnet.private_subnet : subnet.availability_zone => subnet.id }
}
