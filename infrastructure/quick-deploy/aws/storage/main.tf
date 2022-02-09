# AWS KMS
module "kms" {
  source = "../../../modules/aws/kms"
  name   = "armonik-kms-storage-${local.tag}"
  tags   = local.tags
}

# AWS S3 as shared storage
module "s3_bucket_fs" {
  source     = "../../../modules/aws/s3"
  tags       = local.tags
  name       = "${var.s3_bucket_fs.name}-${local.tag}"
  kms_key_id = (var.s3_bucket_fs.kms_key_id != "" ? var.s3_bucket_fs.kms_key_id : module.kms.selected.arn)
}

# AWS Elasticache
module "elasticache" {
  source      = "../../../modules/aws/elasticache"
  tags        = local.tags
  name        = "${var.elasticache.name}-${local.tag}"
  elasticache = {
    engine                = var.elasticache.engine
    engine_version        = var.elasticache.engine_version
    node_type             = var.elasticache.node_type
    encryption_keys       = {
      kms_key_id     = (var.elasticache.encryption_keys.kms_key_id != "" ? var.elasticache.encryption_keys.kms_key_id : module.kms.selected.arn)
      log_kms_key_id = (var.elasticache.encryption_keys.log_kms_key_id != "" ? var.elasticache.encryption_keys.log_kms_key_id : module.kms.selected.arn)
    }
    log_retention_in_days = var.elasticache.log_retention_in_days
    vpc                   = {
      id          = (var.elasticache.vpc.id != "" ? var.elasticache.vpc.id : module.vpc.id)
      cidr_blocks = (length(var.elasticache.vpc.cidr_blocks) != 0 ? var.elasticache.vpc.cidr_blocks : concat([
        module.vpc.cidr_block
      ], module.vpc.pod_cidr_block_private))
      subnet_ids  = (length(var.elasticache.vpc.subnet_ids) != 0 ? var.elasticache.vpc.subnet_ids : module.vpc.private_subnet_ids)
    }
    cluster_mode          = {
      replicas_per_node_group = var.elasticache.cluster_mode.replicas_per_node_group
      num_node_groups         = var.elasticache.cluster_mode.num_node_groups
    }
    multi_az_enabled      = var.elasticache.multi_az_enabled
  }
  depends_on  = [module.vpc]
}

# Amazon MQ
module "mq" {
  source     = "../../../modules/aws/mq"
  tags       = local.tags
  name       = "${var.mq.name}-${local.tag}"
  mq         = {
    engine_type             = var.mq.engine_type
    engine_version          = var.mq.engine_version
    host_instance_type      = var.mq.host_instance_type
    deployment_mode         = var.mq.deployment_mode
    storage_type            = var.mq.storage_type
    kms_key_id              = (var.mq.kms_key_id != "" ? var.mq.kms_key_id : module.kms.selected.arn)
    authentication_strategy = var.mq.authentication_strategy
    publicly_accessible     = var.mq.publicly_accessible
    user                    = {
      password = var.mq_credentials.password
      username = var.mq_credentials.username
    }
    vpc                     = {
      id          = (var.mq.vpc.id != "" ? var.mq.vpc.id : module.vpc.id)
      cidr_blocks = (length(var.mq.vpc.cidr_blocks) != 0 ? var.mq.vpc.cidr_blocks : concat([
        module.vpc.cidr_block
      ], module.vpc.pod_cidr_block_private))
      subnet_ids  = (length(var.mq.vpc.subnet_ids) != 0 ? var.mq.vpc.subnet_ids : module.vpc.private_subnet_ids)
    }
  }
  depends_on = [module.vpc]
}