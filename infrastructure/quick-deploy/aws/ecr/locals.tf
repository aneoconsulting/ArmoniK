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
  random_string = random_string.random_resources.result
  suffix        = var.suffix != null && var.suffix != "" ? var.suffix : local.random_string
  kms_name      = "armonik-kms-ecr-${local.suffix}-${local.random_string}"
  repositories  = [for element in var.ecr.repositories : merge(element, { name = "${local.suffix}/${element.name}" })]
  tags = merge({
    "application"        = "armonik"
    "deployment version" = local.suffix
    "created by"         = data.aws_caller_identity.current.arn
    "date"               = time_static.creation_date.rfc3339
  }, var.tags)
}