locals {
  mongodb_persistent_volume = (try(var.mongodb.persistent_volume.storage_provisioner, "") == "efs.csi.aws.com" ? {
    storage_provisioner = var.mongodb.persistent_volume.storage_provisioner
    resources           = var.mongodb.persistent_volume.resources
    parameters = merge(var.mongodb.persistent_volume.parameters, {
      provisioningMode = "efs-ap"
      fileSystemId     = module.efs_persistent_volume[0].efs_id
      directoryPerms   = "755"
      gidRangeStart    = "999"      # optional
      gidRangeEnd      = "2000"     # optional
      basePath         = "/mongodb" # optional
    })
  } : null)
}

# AWS S3 as shared storage
module "s3_fs" {
  source = "../../../modules/aws/s3"
  tags   = local.tags
  name   = "${local.prefix}-s3fs"
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
    kms_key_id                            = local.kms_key
    sse_algorithm                         = can(coalesce(var.kms_key)) ? var.s3_fs.sse_algorithm : "aws:kms"
  }
}

# AWS Elasticache
module "elasticache" {
  source = "../../../modules/aws/elasticache"
  tags   = local.tags
  name   = "${local.prefix}-elasticache"
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
      kms_key_id     = local.kms_key
      log_kms_key_id = local.kms_key
    }
  }
}

# Amazon MQ
module "mq" {
  source    = "../../../modules/aws/mq"
  tags      = local.tags
  name      = "${local.prefix}-mq"
  namespace = var.namespace
  vpc       = local.vpc
  user      = var.mq_credentials
  mq = {
    engine_type             = var.mq.engine_type
    engine_version          = var.mq.engine_version
    host_instance_type      = var.mq.host_instance_type
    apply_immediately       = var.mq.apply_immediately
    deployment_mode         = var.mq.deployment_mode
    storage_type            = var.mq.storage_type
    authentication_strategy = var.mq.authentication_strategy
    publicly_accessible     = var.mq.publicly_accessible
    kms_key_id              = local.kms_key
  }
}

# MongoDB
module "mongodb" {
  source      = "../../../modules/onpremise-storage/mongodb"
  namespace   = var.namespace
  working_dir = "${path.root}/../../.."
  mongodb = {
    image              = local.ecr_images.mongodb.name
    tag                = local.ecr_images.mongodb.tag
    node_selector      = var.mongodb.node_selector
    image_pull_secrets = var.mongodb.pull_secrets
  }
  persistent_volume = local.mongodb_persistent_volume
}

# AWS EFS as persistent volume
module "efs_persistent_volume" {
  count      = try(var.mongodb.persistent_volume.storage_provisioner, "") == "efs.csi.aws.com" ? 1 : 0
  source     = "../../../modules/persistent-volumes/efs"
  eks_issuer = module.eks.issuer
  vpc        = local.vpc
  efs = {
    name                            = "${local.prefix}-efs"
    kms_key_id                      = local.kms_key
    performance_mode                = var.pv_efs.efs.performance_mode
    throughput_mode                 = var.pv_efs.efs.throughput_mode
    provisioned_throughput_in_mibps = var.pv_efs.efs.provisioned_throughput_in_mibps
    transition_to_ia                = var.pv_efs.efs.transition_to_ia
    access_point                    = var.pv_efs.efs.access_point
  }
  csi_driver = {
    name               = "${local.prefix}-efs-csi-driver"
    namespace          = var.pv_efs.csi_driver.namespace
    image_pull_secrets = var.pv_efs.csi_driver.pull_secrets
    node_selector      = var.pv_efs.csi_driver.node_selector
    docker_images = {
      efs_csi               = local.ecr_images.efs_csi_driver
      livenessprobe         = local.ecr_images.eks_csi_livenessprobe
      node_driver_registrar = local.ecr_images.eks_csi_node_driver_registrar
      external_provisioner  = local.ecr_images.eks_csi_external_provisioner
    }
  }
  tags = local.tags
}




# Decrypt objects in S3
data "aws_iam_policy_document" "decrypt_object" {
  statement {
    sid = "KMSAccess"
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]
    effect = "Allow"
    resources = [
      local.kms_key
    ]
  }
}

resource "aws_iam_policy" "decrypt_object" {
  name_prefix = "${local.prefix}-s3-encrypt-decrypt"
  description = "Policy for alowing decryption of encrypted object in S3 ${module.eks.cluster_id}"
  policy      = data.aws_iam_policy_document.decrypt_object.json
  tags        = local.tags
}

resource "aws_iam_role_policy_attachment" "decrypt_object" {
  policy_arn = aws_iam_policy.decrypt_object.arn
  role       = module.eks.worker_iam_role_name
}

# Read objects in S3
data "aws_iam_policy_document" "read_object" {
  statement {
    sid = "ReadFromS3"
    actions = [
      "s3:GetObject"
    ]
    effect = "Allow"
    resources = [
      "${module.s3_fs.arn}/*"
    ]
  }
}

resource "aws_iam_policy" "read_object" {
  name_prefix = "${local.prefix}-s3-read"
  description = "Policy for allowing read object in S3 ${module.eks.cluster_id}"
  policy      = data.aws_iam_policy_document.read_object.json
  tags        = local.tags
}

resource "aws_iam_role_policy_attachment" "read_object_attachment" {
  policy_arn = aws_iam_policy.read_object.arn
  role       = module.eks.worker_iam_role_name
}
