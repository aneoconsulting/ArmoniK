# Current account
data "aws_caller_identity" "current" {}

resource "random_string" "random_resources" {
  length  = 5
  special = false
  upper   = false
}

# AWS KMS
module "kms" {
  count  = (var.ebs.encrypted && var.ebs.kms_key_id == "" ? 1 : 0)
  source = "../../../../modules/aws/kms"
  name   = "armonik-kms-shared-ebs-${random_string.random_resources.result}"
}

# AWS Elastic Block Store
resource "aws_ebs_volume" "shared_ebs" {
  availability_zone = var.ebs.availability_zone
  size              = var.ebs.size
  encrypted         = var.ebs.encrypted
  kms_key_id        = (var.ebs.kms_key_id != "" ? var.ebs.kms_key_id : module.kms.0.selected.arn)
  tags              = merge(var.ebs.tags, {
    application = "ArmoniK"
    resource    = "EBS"
    created_by  = data.aws_caller_identity.current.arn
    date        = formatdate("EEE-DD-MMM-YY-hh:mm:ss:ZZZ", tostring(timestamp()))
  })
}