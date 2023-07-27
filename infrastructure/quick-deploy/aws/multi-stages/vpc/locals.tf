# Current account
data "aws_caller_identity" "current" {}

resource "random_string" "random_resources" {
  length  = 5
  special = false
  upper   = false
  numeric = true
}

resource "time_static" "creation_date" {}

locals {
  random_string         = random_string.random_resources.result
  suffix                = var.suffix != null && var.suffix != "" ? var.suffix : local.random_string
  cluster_name          = "${var.cluster_name}-${local.suffix}"
  kms_name              = "armonik-kms-vpc-${local.suffix}-${local.random_string}"
  vpc_name              = "${var.vpc.name}-${local.suffix}"
  enable_private_subnet = !var.enable_public_vpc
  tags = merge(var.tags, {
    "application"        = "armonik"
    "deployment version" = local.suffix
    "created by"         = data.aws_caller_identity.current.arn
    "creation date"      = time_static.creation_date.rfc3339
  })
}
