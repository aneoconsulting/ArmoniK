# Secrets
resource "kubernetes_secret" "elasticache_client_certificate" {
  count = length(module.elasticache) > 0 ? 1 : 0
  metadata {
    name      = "redis-user-certificates"
    namespace = var.namespace
  }
  data = {
    "chain.pem" = ""
  }
}

resource "kubernetes_secret" "elasticache_user" {
  count = length(module.elasticache) > 0 ? 1 : 0
  metadata {
    name      = "redis-user"
    namespace = var.namespace
  }
  data = {
    username = ""
    password = ""
  }
  type = "kubernetes.io/basic-auth"
}

resource "kubernetes_secret" "elasticache_endpoints" {
  count = length(module.elasticache) > 0 ? 1 : 0
  metadata {
    name      = "redis-endpoints"
    namespace = var.namespace
  }
  data = {
    host = module.elasticache[0].redis_endpoint_url.host
    port = module.elasticache[0].redis_endpoint_url.port
    url  = module.elasticache[0].redis_endpoint_url.url
  }
}

resource "kubernetes_secret" "mq_client_certificate" {
  metadata {
    name      = "activemq-user-certificates"
    namespace = var.namespace
  }
  data = {
    "chain.pem" = ""
  }
}

resource "kubernetes_secret" "mq_user" {
  metadata {
    name      = "activemq-user"
    namespace = var.namespace
  }
  data = {
    username = module.mq.user.username
    password = module.mq.user.password
  }
  type = "kubernetes.io/basic-auth"
}

resource "kubernetes_secret" "mq_endpoints" {
  metadata {
    name      = "activemq-endpoints"
    namespace = var.namespace
  }
  data = {
    host    = module.mq.activemq_endpoint_url.host
    port    = module.mq.activemq_endpoint_url.port
    url     = module.mq.activemq_endpoint_url.url
    web-url = module.mq.web_url
  }
}

resource "kubernetes_secret" "shared_storage" {
  metadata {
    name      = "shared-storage-endpoints"
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

resource "kubernetes_secret" "s3_user" {
  count = length(module.s3_os) > 0 ? 1 : 0
  metadata {
    name      = "s3-user"
    namespace = var.namespace
  }
  data = {
    username = ""
    password = ""
  }
  type = "kubernetes.io/basic-auth"
}

resource "kubernetes_secret" "s3_endpoints" {
  count = length(module.s3_os) > 0 ? 1 : 0
  metadata {
    name      = "s3-endpoints"
    namespace = var.namespace
  }
  data = {
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