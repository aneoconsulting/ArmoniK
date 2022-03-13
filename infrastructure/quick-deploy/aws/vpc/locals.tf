# Current account
data "aws_caller_identity" "current" {}

resource "random_string" "random_resources" {
  length  = 5
  special = false
  upper   = false
  number  = true
}

locals {
  random_string = random_string.random_resources.result
  suffix        = var.suffix != null && var.suffix != "" ? var.suffix : local.random_string
  cluster_name  = "${var.cluster_name}-${local.suffix}"
  kms_name      = "armonik-kms-vpc-${local.suffix}-${local.random_string}"
  vpc_name      = "${var.vpc.name}-${local.suffix}"
  tags          = merge(var.tags, {
    application        = "ArmoniK"
    deployment_version = local.suffix
    created_by         = data.aws_caller_identity.current.arn
    date               = formatdate("EEE-DD-MMM-YY-hh:mm:ss:ZZZ", tostring(timestamp()))
  })
}