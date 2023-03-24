# Current account
data "aws_caller_identity" "current" {}

resource "random_string" "prefix" {
  length  = 5
  special = false
  upper   = false
  numeric = true
}

locals {
  prefix = try(coalesce(var.prefix), "armonik-${random_string.prefix.result}")
  tags = merge({
    "application"        = "armonik"
    "deployment version" = local.prefix
    "created by"         = data.aws_caller_identity.current.arn
    "creation date"      = null_resource.timestamp.triggers["creation_date"]
  }, var.tags)
}

# this external provider is used to get date during the plan step.
data "external" "static_timestamp" {
  program = ["date", "+{ \"creation_date\": \"%Y/%M/%d %T\" }"]
}

# this resource is just used to prevent change of the creation_date during successive 'terraform apply'
resource "null_resource" "timestamp" {
  triggers = {
    creation_date = data.external.static_timestamp.result.creation_date
  }
  lifecycle {
    ignore_changes = [triggers]
  }
}
