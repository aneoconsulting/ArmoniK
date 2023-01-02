# Current account
data "aws_caller_identity" "current" {}

resource "random_string" "prefix" {
  length  = 5
  special = false
  upper   = false
  numeric = true
}

locals {
  prefix = var.prefix != null && var.prefix != "" ? var.prefix : "armonik-${random_string.prefix.result}"
  tags = merge({
    "application"        = "armonik"
    "deployment version" = local.prefix
    "created by"         = data.aws_caller_identity.current.arn
    "date"               = formatdate("EEE-DD-MMM-YY-hh:mm:ss:ZZZ", tostring(timestamp()))
  }, var.tags)
}
