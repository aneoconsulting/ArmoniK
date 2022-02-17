# Current account
data "aws_caller_identity" "current" {}

resource "random_string" "random_resources" {
  length  = 5
  special = false
  upper   = false
  number  = true
}

locals {
  random_string    = random_string.random_resources.result
  suffix           = var.suffix != null && var.suffix != "" ? var.suffix : local.random_string
  tags             = merge(var.tags, {
    application        = "ArmoniK"
    deployment_version = local.suffix
    created_by         = data.aws_caller_identity.current.arn
    date               = formatdate("EEE-DD-MMM-YY-hh:mm:ss:ZZZ", tostring(timestamp()))
  })
  s3_fs_kms_key_id = (var.s3_fs.kms_key_id != "" ? var.s3_fs.kms_key_id : module.kms.0.selected.arn)
}