# Current account
data "aws_caller_identity" "current" {}

# VPC of ArmoniK EKS
data "aws_vpc" "armonik_vpc" {
  id = var.armonik_vpc_id
}

# Private subnets of ArmoniK EKS VPC
data "aws_subnet_ids" "armonik_private_subnet_ids" {
  vpc_id = var.armonik_vpc_id
  tags   = {
    Tier = "Private"
  }
}

data "aws_subnet" "armonik_private_subnet" {
  for_each = data.aws_subnet_ids.armonik_private_subnet_ids.ids
  id       = each.value
}

resource "random_string" "random_resources" {
  length  = 5
  special = false
  upper   = false
}

locals {
  tag                    = var.tag != null && var.tag != "" ? var.tag : random_string.random_resources.result
  vpc_private_subnet_ids = [for subnet in data.aws_subnet.armonik_private_subnet : subnet.id]
  vpc_cidr_blocks        = concat(
  [
    data.aws_vpc.armonik_vpc.cidr_block
  ],
  [
  for subnet in data.aws_subnet.armonik_private_subnet : subnet.cidr_block
  ])
  tags                   = {
    application = "ArmoniK"
    created_by  = data.aws_caller_identity.current.arn
    date        = formatdate("EEE-DD-MMM-YY-hh:mm:ss:ZZZ", tostring(timestamp()))
  }
}