# ActiveMQ
module "activemq" {
  count     = var.activemq != null ? 1 : 0
  source    = "./generated/infra-modules/storage/onpremise/activemq"
  namespace = local.namespace
  activemq = {
    image                = var.activemq.image_name
    tag                  = try(coalesce(var.activemq.image_tag), local.default_tags[var.activemq.image_name])
    node_selector        = var.activemq.node_selector
    image_pull_secrets   = var.activemq.image_pull_secrets
    limits               = var.activemq.limits
    requests             = var.activemq.requests
    activemq_opts_memory = var.activemq.activemq_opts_memory
  }
}

module "rabbitmq" {
  count                 = var.rabbitmq != null ? 1 : 0
  source                = "./generated/infra-modules/storage/onpremise/rabbitmq"
  namespace             = local.namespace
  image                 = var.rabbitmq.image
  tag                   = try(coalesce(var.rabbitmq.tag), local.default_tags[var.rabbitmq.image])
  helm_chart_repository = try(coalesce(var.rabbitmq.helm_chart_repository), var.helm_charts.rabbitmq.repository)
  helm_chart_version    = try(coalesce(var.rabbitmq.helm_chart_verison), var.helm_charts.rabbitmq.version)
}


# MongoDB (Percona Operator)
module "mongodb" {
  count     = var.mongodb != null ? 1 : 0
  source    = "./generated/infra-modules/storage/onpremise/mongodb-percona"
  namespace = local.namespace
  name      = "percona-mongodb"

  operator = merge(var.mongodb.operator, {
    tag           = coalesce(var.mongodb.operator.tag, local.default_tags[coalesce(var.mongodb.operator.image, "percona/percona-server-mongodb-operator")])
    node_selector = coalesce(var.mongodb.operator.node_selector, var.mongodb.node_selector)

  })
  cluster = merge(var.mongodb.cluster, {
    tag           = coalesce(var.mongodb.cluster.tag, local.default_tags[coalesce(var.mongodb.cluster.image, "percona/percona-server-mongodb")])
    node_selector = coalesce(var.mongodb.cluster.node_selector, var.mongodb.node_selector)
  })

  resources = var.mongodb.resources

  sharding = var.mongodb.sharding

  persistence = var.mongodb.persistence

  timeout = var.mongodb.timeout
}

# Redis
module "redis" {
  count     = var.redis != null ? 1 : 0
  source    = "./generated/infra-modules/storage/onpremise/redis"
  namespace = local.namespace
  redis = {
    image              = var.redis.image_name
    tag                = try(coalesce(var.redis.image_tag), local.default_tags[var.redis.image_name])
    node_selector      = var.redis.node_selector
    image_pull_secrets = var.redis.image_pull_secrets
    max_memory         = var.redis.max_memory
    max_memory_samples = var.redis.max_memory_samples
  }
}

# minio
module "minio" {
  count     = var.minio != null ? 1 : 0
  source    = "./generated/infra-modules/storage/onpremise/minio"
  namespace = local.namespace
  minio = {
    image              = var.minio.image_name
    tag                = try(coalesce(var.minio.image_tag), local.default_tags[var.minio.image_name])
    node_selector      = var.minio.node_selector
    image_pull_secrets = var.minio.image_pull_secrets
    host               = var.minio.host
    bucket_name        = var.minio.default_bucket
  }
}

# minio for file storage
module "minio_s3_fs" {
  count     = var.minio_s3_fs != null ? 1 : 0
  source    = "./generated/infra-modules/storage/onpremise/minio"
  namespace = local.namespace
  minio = {
    image              = local.minio_s3_fs_image
    tag                = try(coalesce(var.minio.image_tag), local.default_tags[var.minio_s3_fs.image_name])
    image_pull_secrets = local.minio_s3_fs_image_pull_secrets
    host               = local.minio_s3_fs_host
    bucket_name        = local.minio_s3_fs_bucket_name
    node_selector      = local.minio_s3_fs_node_selector
  }
}

#NFS
module "nfs" {
  count     = var.nfs != null ? 1 : 0
  source    = "./generated/infra-modules/storage/onpremise/nfs"
  image     = var.nfs.image
  tag       = try(coalesce(var.nfs.tag), local.default_tags[var.nfs.image])
  namespace = local.namespace
  server    = var.nfs.server
  path      = var.nfs.path
  pvc_name  = var.nfs.pvc_name
}

# Shared storage

resource "kubernetes_secret" "shared_storage" {
  metadata {
    name      = "shared-storage"
    namespace = var.namespace
  }

  data = local.shared_storage
}
