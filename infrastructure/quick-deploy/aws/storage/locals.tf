# Current account
data "aws_caller_identity" "current" {}

resource "random_string" "random_resources" {
  length  = 5
  special = false
  upper   = false
  number  = true
}

locals {
  random_string                     = random_string.random_resources.result
  suffix                            = var.suffix != null && var.suffix != "" ? var.suffix : local.random_string
  iam_s3_decrypt_object_policy_name = "s3-encrypt-decrypt-${var.eks.cluster_id}"
  kms_name                          = "armonik-kms-storage-${local.suffix}-${local.random_string}"
  s3_fs_name                        = "${var.s3_fs.name}-${local.suffix}"
  elasticache_name                  = "${var.elasticache.name}-${local.suffix}"
  mq_name                           = "${var.mq.name}-${local.suffix}"
  tags = merge(var.tags, {
    "application"        = "armonik"
    "deployment version" = local.suffix
    "created by"         = data.aws_caller_identity.current.arn
    "date"               = formatdate("EEE-DD-MMM-YY-hh:mm:ss:ZZZ", tostring(timestamp()))
  })
  s3_fs_kms_key_id = (var.s3_fs.kms_key_id != "" ? var.s3_fs.kms_key_id : module.kms.0.selected.arn)
  vpc = {
    id          = try(var.vpc.id, "")
    cidr_blocks = concat([try(var.vpc.cidr_block, "")], try(var.vpc.pod_cidr_block_private, []))
    subnet_ids  = try(var.vpc.private_subnet_ids, [])
  }
}