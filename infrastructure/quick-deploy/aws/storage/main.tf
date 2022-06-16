# AWS KMS
module "kms" {
  count  = (var.s3_fs.kms_key_id != "" && var.elasticache.encryption_keys.kms_key_id != "" && var.elasticache.encryption_keys.log_kms_key_id != "" && var.mq.kms_key_id != "" ? 0 : 1)
  source = "../../../modules/aws/kms"
  name   = local.kms_name
  tags   = local.tags
}

# AWS S3 as shared storage
module "s3_fs" {
  source = "../../../modules/aws/s3"
  tags   = local.tags
  name   = local.s3_fs_name
  s3     = {
    policy                                = var.s3_fs.policy
    attach_policy                         = var.s3_fs.attach_policy
    attach_deny_insecure_transport_policy = var.s3_fs.attach_deny_insecure_transport_policy
    attach_require_latest_tls_policy      = var.s3_fs.attach_require_latest_tls_policy
    attach_public_policy                  = var.s3_fs.attach_public_policy
    block_public_acls                     = var.s3_fs.attach_public_policy
    block_public_policy                   = var.s3_fs.block_public_acls
    ignore_public_acls                    = var.s3_fs.block_public_policy
    restrict_public_buckets               = var.s3_fs.restrict_public_buckets
    kms_key_id                            = local.s3_fs_kms_key_id
    sse_algorithm                         = (var.s3_fs.kms_key_id != "" ? var.s3_fs.sse_algorithm : "aws:kms")
  }
}

# AWS Elasticache
module "elasticache" {
  source      = "../../../modules/aws/elasticache"
  tags        = local.tags
  name        = local.elasticache_name
  vpc         = {
    id          = local.vpc.id
    cidr_blocks = local.vpc.cidr_blocks
    subnet_ids  = local.vpc.subnet_ids
  }
  elasticache = {
    engine                      = var.elasticache.engine
    engine_version              = var.elasticache.engine_version
    node_type                   = var.elasticache.node_type
    apply_immediately           = var.elasticache.apply_immediately
    multi_az_enabled            = var.elasticache.multi_az_enabled
    automatic_failover_enabled  = var.elasticache.automatic_failover_enabled
    num_cache_clusters          = var.elasticache.num_cache_clusters
    preferred_cache_cluster_azs = var.elasticache.preferred_cache_cluster_azs
    data_tiering_enabled        = var.elasticache.data_tiering_enabled
    log_retention_in_days       = var.elasticache.log_retention_in_days
    cloudwatch_log_groups       = var.elasticache.cloudwatch_log_groups
    encryption_keys             = {
      kms_key_id     = (var.elasticache.encryption_keys.kms_key_id != "" ? var.elasticache.encryption_keys.kms_key_id : module.kms.0.selected.arn)
      log_kms_key_id = (var.elasticache.encryption_keys.log_kms_key_id != "" ? var.elasticache.encryption_keys.log_kms_key_id : module.kms.0.selected.arn)
    }
  }
}

# Amazon MQ
module "mq" {
  source    = "../../../modules/aws/mq"
  tags      = local.tags
  name      = local.mq_name
  namespace = var.namespace
  vpc       = {
    id          = local.vpc.id
    cidr_blocks = local.vpc.cidr_blocks
    subnet_ids  = local.vpc.subnet_ids
  }
  user      = {
    password = var.mq_credentials.password
    username = var.mq_credentials.username
  }
  mq        = {
    engine_type             = var.mq.engine_type
    engine_version          = var.mq.engine_version
    host_instance_type      = var.mq.host_instance_type
    apply_immediately       = var.mq.apply_immediately
    deployment_mode         = var.mq.deployment_mode
    storage_type            = var.mq.storage_type
    authentication_strategy = var.mq.authentication_strategy
    publicly_accessible     = var.mq.publicly_accessible
    kms_key_id              = (var.mq.kms_key_id != "" ? var.mq.kms_key_id : module.kms.0.selected.arn)
  }
}

# MongoDB
module "mongodb" {
  source      = "../../../modules/onpremise-storage/mongodb"
  namespace   = var.namespace
  working_dir = "${path.root}/../../.."
  mongodb     = {
    image              = var.mongodb.image
    tag                = var.mongodb.tag
    node_selector      = var.mongodb.node_selector
    image_pull_secrets = var.mongodb.image_pull_secrets
  }
}