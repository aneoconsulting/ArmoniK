# Profile
profile = "default"

# Region
region = "eu-west-3"

# SUFFIX
suffix = "main"

# AWS TAGs
tags = {
  "name"             = ""
  "env"              = ""
  "entity"           = ""
  "bu"               = ""
  "owner"            = ""
  "application code" = ""
  "project code"     = ""
  "cost center"      = ""
  "Support Contact"  = ""
  "origin"           = "terraform"
  "unit of measure"  = ""
  "epic"             = ""
  "functional block" = ""
  "hostname"         = ""
  "interruptible"    = ""
  "tostop"           = ""
  "tostart"          = ""
  "branch"           = ""
  "gridserver"       = ""
  "it division"      = ""
  "Confidentiality"  = ""
  "csp"              = "aws"
  "grafanaserver"    = ""
  "Terraform"        = "true"
  "DST_Update"       = ""
}

# Kubernetes namespace
namespace = "armonik"

# S3 as shared storage
s3_fs = {
  name                                  = "armonik-s3fs"
  policy                                = ""
  attach_policy                         = false
  attach_deny_insecure_transport_policy = true
  attach_require_latest_tls_policy      = true
  attach_public_policy                  = false
  block_public_acls                     = true
  block_public_policy                   = true
  ignore_public_acls                    = true
  restrict_public_buckets               = true
  kms_key_id                            = ""
  sse_algorithm                         = ""
}

# Object storage
# Uncomment either the `Elasticache` or the `S3` parameter
# AWS Elasticache
elasticache = {
  name                        = "armonik-elasticache"
  engine                      = "redis"
  engine_version              = "6.x"
  node_type                   = "cache.r4.large"
  apply_immediately           = true
  multi_az_enabled            = false
  automatic_failover_enabled  = true
  num_cache_clusters          = 2
  preferred_cache_cluster_azs = []
  # The order of the availability zones in the list is considered. The first item in the list will be the primary node
  data_tiering_enabled  = false # This parameter must be set to true when using r6gd nodes.
  log_retention_in_days = 30
  # Name of CloudWatch log groups for slow-log and engine-log to be created
  cloudwatch_log_groups = {
    slow_log   = ""
    engine_log = ""
  }
  encryption_keys = {
    kms_key_id     = ""
    log_kms_key_id = ""
  }
}

# S3 as shared storage
/*s3_os = {
  name                                  = "armonik-s3os"
  policy                                = ""
  attach_policy                         = false
  attach_deny_insecure_transport_policy = true
  attach_require_latest_tls_policy      = true
  attach_public_policy                  = false
  block_public_acls                     = true
  block_public_policy                   = true
  ignore_public_acls                    = true
  restrict_public_buckets               = true
  kms_key_id                            = ""
  sse_algorithm                         = ""
}*/

# MQ parameters
mq = {
  name                    = "armonik-mq"
  engine_type             = "ActiveMQ"
  engine_version          = "5.16.4"
  host_instance_type      = "mq.m5.xlarge"
  apply_immediately       = true
  deployment_mode         = "SINGLE_INSTANCE" # "SINGLE_INSTANCE" | "ACTIVE_STANDBY_MULTI_AZ"
  storage_type            = "ebs"             # "ebs" | "efs"
  kms_key_id              = ""
  authentication_strategy = "simple" # "ldap"
  publicly_accessible     = false
}

# MQ Credentials
mq_credentials = {
  password = ""
  username = ""
}

# Parameters for MongoDB
mongodb = {
  image              = "125796369274.dkr.ecr.eu-west-3.amazonaws.com/mongodb"
  tag                = "6.0.1"
  node_selector      = { "grid/type" = "Operator" }
  image_pull_secrets = ""
  #persistent_volume  = null
  persistent_volume = { storage_provisioner = "efs.csi.aws.com", parameters = null, resources = { limits = null, requests = { storage = "5Gi" } } }
  # example: {storage_provisioner="efs.csi.aws.com",parameters=null,resources={limits=null,requests={storage="5Gi"}}}
}

# AWS EFS as Persistent volume
pv_efs = {
  # AWS Elastic Filesystem Service
  efs = {
    name                            = "armonik-efs"
    kms_key_id                      = ""
    performance_mode                = "generalPurpose" # "generalPurpose" or "maxIO"
    throughput_mode                 = "bursting"       #  "bursting" or "provisioned"
    provisioned_throughput_in_mibps = null
    transition_to_ia                = "AFTER_7_DAYS"
    # "AFTER_7_DAYS", "AFTER_14_DAYS", "AFTER_30_DAYS", "AFTER_60_DAYS", or "AFTER_90_DAYS"
    access_point = null #["mongo"]
  }
  # EFS Container Storage Interface (CSI) Driver
  csi_driver = {
    namespace          = "kube-system"
    image_pull_secrets = ""
    node_selector      = { "grid/type" = "Operator" }
    docker_images = {
      efs_csi = {
        image = "125796369274.dkr.ecr.eu-west-3.amazonaws.com/aws-efs-csi-driver"
        tag   = "v1.5.1"
      }
      livenessprobe = {
        image = "125796369274.dkr.ecr.eu-west-3.amazonaws.com/livenessprobe"
        tag   = "v2.9.0-eks-1-22-19"
      }
      node_driver_registrar = {
        image = "125796369274.dkr.ecr.eu-west-3.amazonaws.com/node-driver-registrar"
        tag   = "v2.7.0-eks-1-22-19"
      }
      external_provisioner = {
        image = "125796369274.dkr.ecr.eu-west-3.amazonaws.com/external-provisioner"
        tag   = "v3.4.0-eks-1-22-19"
      }
    }
  }
}
