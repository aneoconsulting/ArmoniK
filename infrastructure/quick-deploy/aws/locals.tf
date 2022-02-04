# Current account
data "aws_caller_identity" "current" {}

resource "random_string" "random_resources" {
  length  = 5
  special = false
  upper   = false
}

locals {
  tag          = var.tag != null && var.tag != "" ? var.tag : random_string.random_resources.result
  cluster_name = "armonik-eks-${local.tag}"
  tags         = {
    application        = "ArmoniK"
    deployment_version = local.tag
    created_by         = data.aws_caller_identity.current.arn
    date               = formatdate("EEE-DD-MMM-YY-hh:mm:ss:ZZZ", tostring(timestamp()))
  }
}