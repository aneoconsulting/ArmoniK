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
  tag           = var.tag != null && var.tag != "" ? var.tag : local.random_string
  tags          = {
    application        = "ArmoniK"
    deployment_version = local.tag
    created_by         = data.aws_caller_identity.current.arn
    date               = formatdate("EEE-DD-MMM-YY-hh:mm:ss:ZZZ", tostring(timestamp()))
  }
}