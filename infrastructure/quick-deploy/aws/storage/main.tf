# AWS KMS
module "kms" {
  count  = (can(coalesce(var.s3_fs.kms_key_id)) && can(coalesce(var.elasticache.encryption_keys.kms_key_id)) && can(coalesce(var.elasticache.encryption_keys.log_kms_key_id)) && can(coalesce(var.s3_os.kms_key_id)) && can(coalesce(var.mq.kms_key_id)) ? 0 : 1)
  source = "../generated/infra-modules/aws/kms"
  name   = local.kms_name
  tags   = local.tags
}

# AWS S3 as shared storage
module "s3_fs" {
  source = "../generated/infra-modules/aws/s3"
  tags   = local.tags
  name   = local.s3_fs_name
  s3 = {
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
    ownership                             = var.s3_fs.ownership
    versioning                            = var.s3_fs.versioning
  }
}

# AWS Elasticache
module "elasticache" {
  count  = var.elasticache != null ? 1 : 0
  source = "../generated/infra-modules/aws/elasticache"
  tags   = local.tags
  name   = local.elasticache_name
  vpc    = local.vpc
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
    encryption_keys = {
      kms_key_id     = (var.elasticache.encryption_keys.kms_key_id != "" ? var.elasticache.encryption_keys.kms_key_id : module.kms.0.arn)
      log_kms_key_id = (var.elasticache.encryption_keys.log_kms_key_id != "" ? var.elasticache.encryption_keys.log_kms_key_id : module.kms.0.arn)
    }
  }
}

# AWS S3 as objects storage
module "s3_os" {
  count  = var.s3_os != null ? 1 : 0
  source = "../generated/infra-modules/aws/s3"
  tags   = local.tags
  name   = local.s3_os_name
  s3 = {
    policy                                = var.s3_os.policy
    attach_policy                         = var.s3_os.attach_policy
    attach_deny_insecure_transport_policy = var.s3_os.attach_deny_insecure_transport_policy
    attach_require_latest_tls_policy      = var.s3_os.attach_require_latest_tls_policy
    attach_public_policy                  = var.s3_os.attach_public_policy
    block_public_acls                     = var.s3_os.attach_public_policy
    block_public_policy                   = var.s3_os.block_public_acls
    ignore_public_acls                    = var.s3_os.block_public_policy
    restrict_public_buckets               = var.s3_os.restrict_public_buckets
    kms_key_id                            = local.s3_os_kms_key_id
    sse_algorithm                         = (var.s3_os.kms_key_id != "" ? var.s3_os.sse_algorithm : "aws:kms")
    ownership                             = var.s3_os.ownership
    versioning                            = var.s3_os.versioning
  }
}

# Amazon MQ
module "mq" {
  source    = "../generated/infra-modules/aws/mq"
  tags      = local.tags
  name      = local.mq_name
  namespace = var.namespace
  vpc       = local.vpc
  user = {
    password = var.mq_credentials.password
    username = var.mq_credentials.username
  }
  mq = {
    engine_type             = var.mq.engine_type
    engine_version          = var.mq.engine_version
    host_instance_type      = var.mq.host_instance_type
    apply_immediately       = var.mq.apply_immediately
    deployment_mode         = var.mq.deployment_mode
    storage_type            = var.mq.storage_type
    authentication_strategy = var.mq.authentication_strategy
    publicly_accessible     = var.mq.publicly_accessible
    kms_key_id              = (var.mq.kms_key_id != "" ? var.mq.kms_key_id : module.kms.0.arn)
  }
}

# MongoDB
module "mongodb" {
  source      = "../generated/infra-modules/onpremise-storage/mongodb"
  namespace   = var.namespace
  working_dir = "${path.root}/../../.."
  mongodb = {
    image              = var.mongodb.image
    tag                = var.mongodb.tag
    node_selector      = var.mongodb.node_selector
    image_pull_secrets = var.mongodb.image_pull_secrets
    replicas_number    = var.mongodb.replicas_number
  }
  persistent_volume = local.persistent_volume
  depends_on        = [module.efs_persistent_volume]
}

# AWS EFS as persistent volume
module "efs_persistent_volume" {
  count      = (try(var.mongodb.persistent_volume.storage_provisioner, "") == "efs.csi.aws.com" ? 1 : 0)
  source     = "../generated/infra-modules/persistent-volumes/efs"
  eks_issuer = var.eks.issuer
  vpc        = local.vpc
  efs = {
    name                            = local.efs_name
    kms_key_id                      = (var.pv_efs.efs.kms_key_id != "" && var.pv_efs.efs.kms_key_id != null ? var.pv_efs.efs.kms_key_id : module.kms.0.arn)
    performance_mode                = var.pv_efs.efs.performance_mode
    throughput_mode                 = var.pv_efs.efs.throughput_mode
    provisioned_throughput_in_mibps = var.pv_efs.efs.provisioned_throughput_in_mibps
    transition_to_ia                = var.pv_efs.efs.transition_to_ia
    access_point                    = var.pv_efs.efs.access_point
  }
  csi_driver = {
    name               = local.efs_csi_name
    namespace          = var.pv_efs.csi_driver.namespace
    image_pull_secrets = var.pv_efs.csi_driver.image_pull_secrets
    node_selector      = var.pv_efs.csi_driver.node_selector
    repository         = var.pv_efs.csi_driver.repository
    version            = var.pv_efs.csi_driver.version
    docker_images = {
      efs_csi = {
        image = var.pv_efs.csi_driver.docker_images.efs_csi.image
        tag   = var.pv_efs.csi_driver.docker_images.efs_csi.tag
      }
      livenessprobe = {
        image = var.pv_efs.csi_driver.docker_images.livenessprobe.image
        tag   = var.pv_efs.csi_driver.docker_images.livenessprobe.tag
      }
      node_driver_registrar = {
        image = var.pv_efs.csi_driver.docker_images.node_driver_registrar.image
        tag   = var.pv_efs.csi_driver.docker_images.node_driver_registrar.tag
      }
      external_provisioner = {
        image = var.pv_efs.csi_driver.docker_images.external_provisioner.image
        tag   = var.pv_efs.csi_driver.docker_images.external_provisioner.tag
      }
    }
  }
  tags = local.tags
}