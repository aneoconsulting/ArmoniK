# Cache
# Redis
module "cache" {
  count     = var.cache != null ? 1 : 0
  source    = "./generated/infra-modules/storage/onpremise/redis"
  namespace = local.external_data_plane_namespace
  redis = {
    image              = var.cache.image_name
    tag                = try(coalesce(var.cache.image_tag), local.default_tags[var.cache.image_name])
    node_selector      = var.cache.node_selector
    image_pull_secrets = var.cache.image_pull_secrets
    max_memory         = var.cache.max_memory
    service_type       = var.cache.service_type
  }
}

resource "kubernetes_secret" "deployed_cache_storage" {
  count = length(module.cache)
  metadata {
    name      = "deployed-cache-storage"
    namespace = local.external_data_plane_namespace
  }
  data = {
    list    = "Redis"
    adapter = "Redis"
  }
}

# Storage
locals {
  external_storage_endpoint_url = {
    cache = length(module.cache) > 0 ? {
      url          = module.cache[0].url
      host         = module.cache[0].host
      port         = module.cache[0].port
      credentials  = module.cache[0].user_credentials
      certificates = module.cache[0].user_certificate
      endpoints    = module.cache[0].endpoints
      timeout      = 30000
      ssl_host     = "127.0.0.1"
    } : null
  }
}
