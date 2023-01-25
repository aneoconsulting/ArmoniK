# Secrets
resource "kubernetes_secret" "elasticache_endpoints" {
  metadata {
    name      = "redis-endpoints"
    namespace = var.namespace
  }
  data = {
    host = module.elasticache.redis_endpoint_url.host
    port = module.elasticache.redis_endpoint_url.port
    url  = module.elasticache.redis_endpoint_url.url
  }
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