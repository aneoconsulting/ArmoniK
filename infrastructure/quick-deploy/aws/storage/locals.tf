# Current account
data "aws_caller_identity" "current" {}

# Random alphanumeric
resource "random_string" "random_resources" {
  length  = 5
  special = false
  upper   = false
  numeric = true
}

resource "time_static" "creation_date" {}

locals {
  random_string                                = random_string.random_resources.result
  suffix                                       = var.suffix != null && var.suffix != "" ? var.suffix : local.random_string
  iam_s3_decrypt_object_policy_name            = "s3-encrypt-decrypt-${var.eks.cluster_id}"
  iam_s3_read_object_policy_name               = "s3-read-${var.eks.cluster_id}"
  iam_s3_decrypt_s3_storage_object_policy_name = "s3-storage-object-encrypt-decrypt-${var.eks.cluster_id}"
  kms_name                                     = "armonik-kms-storage-${local.suffix}-${local.random_string}"
  s3_fs_name                                   = "${var.s3_fs.name}-${local.suffix}"
  s3_os_name                                   = var.s3_os != null ? "${var.s3_os.name}-${local.suffix}" : ""
  elasticache_name                             = var.elasticache != null ? "${var.elasticache.name}-${local.suffix}" : ""
  mq_name                                      = "${var.mq.name}-${local.suffix}"
  efs_name                                     = "${var.pv_efs.efs.name}-${local.suffix}"
  efs_csi_name                                 = "efs-csi-driver-${local.suffix}"
  persistent_volume = (try(var.mongodb.persistent_volume.storage_provisioner, "") == "efs.csi.aws.com" ? {
    storage_provisioner = var.mongodb.persistent_volume.storage_provisioner
    resources           = var.mongodb.persistent_volume.resources
    parameters = merge(var.mongodb.persistent_volume.parameters, {
      provisioningMode = "efs-ap"
      fileSystemId     = module.efs_persistent_volume.0.efs_id
      directoryPerms   = "755"
      gidRangeStart    = "999"      # optional
      gidRangeEnd      = "2000"     # optional
      basePath         = "/mongodb" # optional
    })
  } : null)

  tags = merge(var.tags, {
    "application"        = "armonik"
    "deployment version" = local.suffix
    "created by"         = data.aws_caller_identity.current.arn
    "creation date"               = time_static.creation_date.rfc3339
  })
  s3_fs_kms_key_id = (var.s3_fs.kms_key_id != "" ? var.s3_fs.kms_key_id : module.kms.0.arn)
  s3_os_kms_key_id = (can(coalesce(var.s3_os.kms_key_id)) ? var.s3_os.kms_key_id : module.kms.0.arn)
  vpc = {
    id                 = try(var.vpc.id, "")
    cidr_block_private = var.vpc.cidr_block_private
    cidr_blocks        = concat([try(var.vpc.cidr_block, "")], try(var.vpc.pod_cidr_block_private, []))
    subnet_ids         = try(var.vpc.private_subnet_ids, [])
  }

  # Deployed storage
  deployed_object_storages = concat(
    length(module.elasticache) > 0 ? ["Redis"] : [],
    length(module.s3_os) > 0 ? ["S3"] : [],
  )
  deployed_table_storages = ["MongoDB"]
  deployed_queue_storages = ["Amqp"]

  # Storage adapters
  object_storage_adapter = try(coalesce(
    length(module.elasticache) > 0 ? "Redis" : null,
    length(module.s3_os) > 0 ? "S3" : null,
  ), "")
  table_storage_adapter = "MongoDB"
  queue_storage_adapter = "Amqp"
}
