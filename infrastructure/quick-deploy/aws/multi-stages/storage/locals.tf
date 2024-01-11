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
  iam_s3_decrypt_object_policy_name            = "s3-encrypt-decrypt-${var.eks.cluster_name}"
  iam_s3_read_object_policy_name               = "s3-read-${var.eks.cluster_name}"
  iam_s3_decrypt_s3_storage_object_policy_name = "s3-storage-object-encrypt-decrypt-${var.eks.cluster_name}"
  s3_fs_name                                   = "${var.s3_fs.name}-${local.suffix}"
  s3_os_name                                   = var.s3_os != null ? "${var.s3_os.name}-${local.suffix}" : ""
  elasticache_name                             = var.elasticache != null ? "${var.elasticache.name}-${local.suffix}" : ""
  mq_name                                      = "${var.mq.name}-${local.suffix}"

  tags = merge(var.tags, {
    "application"        = "armonik"
    "deployment version" = local.suffix
    "created by"         = data.aws_caller_identity.current.arn
    "creation date"      = time_static.creation_date.rfc3339
  })

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
  adapter_class_name    = module.mq.engine_type == "ActiveMQ" ? "ArmoniK.Core.Adapters.Amqp.QueueBuilder" : "ArmoniK.Core.Adapters.RabbitMQ.QueueBuilder"
  adapter_absolute_path = module.mq.engine_type == "ActiveMQ" ? "/adapters/queue/amqp/ArmoniK.Core.Adapters.Amqp.dll" : "/adapters/queue/rabbit/ArmoniK.Core.Adapters.RabbitMQ.dll"
}
