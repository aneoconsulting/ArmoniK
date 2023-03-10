# Current account
data "aws_caller_identity" "current" {}

resource "random_string" "prefix" {
  length  = 5
  special = false
  upper   = false
  numeric = true
}


resource "time_static" "creation_date" {}


locals {
  prefix = try(coalesce(var.prefix), "armonik-${random_string.prefix.result}")
  tags = merge({
    "application"        = "armonik"
    "deployment version" = local.prefix
    "created by"         = data.aws_caller_identity.current.arn
    "date"               = time_static.creation_date.rfc3339
  }, var.tags)
}
