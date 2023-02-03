# Secrets
resource "kubernetes_secret" "elasticache" {
  count = length(module.elasticache) > 0 ? 1 : 0
  metadata {
    name      = "redis"
    namespace = var.namespace
  }
  data = {
    "chain.pem" = ""
    username    = ""
    password    = ""
    host        = module.elasticache[0].redis_endpoint_url.host
    port        = module.elasticache[0].redis_endpoint_url.port
    url         = module.elasticache[0].redis_endpoint_url.url
  }
}

resource "kubernetes_secret" "mq" {
  metadata {
    name      = "activemq"
    namespace = var.namespace
  }
  data = {
    "chain.pem" = ""
    username    = module.mq.user.username
    password    = module.mq.user.password
    host        = module.mq.activemq_endpoint_url.host
    port        = module.mq.activemq_endpoint_url.port
    url         = module.mq.activemq_endpoint_url.url
    web-url     = module.mq.web_url
  }
}

resource "kubernetes_secret" "shared_storage" {
  metadata {
    name      = "shared-storage"
    namespace = var.namespace
  }
  data = {
    service_url       = "https://s3.${var.region}.amazonaws.com"
    kms_key_id        = module.s3_fs.kms_key_id
    name              = module.s3_fs.s3_bucket_name
    access_key_id     = ""
    secret_access_key = ""
    file_storage_type = "S3"
  }
}

resource "kubernetes_secret" "s3" {
  count = length(module.s3_os) > 0 ? 1 : 0
  metadata {
    name      = "s3"
    namespace = var.namespace
  }
  data = {
    username              = ""
    password              = ""
    url                   = "https://s3.${var.region}.amazonaws.com"
    bucket_name           = module.s3_os[0].s3_bucket_name
    kms_key_id            = module.s3_os[0].kms_key_id
    must_force_path_style = false
  }
}

resource "kubernetes_secret" "deployed_object_storage" {
  metadata {
    name      = "deployed-object-storage"
    namespace = var.namespace
  }
  data = {
    list    = join(",", local.deployed_object_storages)
    adapter = local.object_storage_adapter
  }
}

resource "kubernetes_secret" "deployed_table_storage" {
  metadata {
    name      = "deployed-table-storage"
    namespace = var.namespace
  }
  data = {
    list    = join(",", local.deployed_table_storages)
    adapter = local.table_storage_adapter
  }
}

resource "kubernetes_secret" "deployed_queue_storage" {
  metadata {
    name      = "deployed-queue-storage"
    namespace = var.namespace
  }
  data = {
    list    = join(",", local.deployed_queue_storages)
    adapter = local.queue_storage_adapter
  }
}