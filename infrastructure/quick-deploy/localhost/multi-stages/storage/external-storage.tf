# Cache
# Redis
module "cache" {
  count     = var.cache != null ? 1 : 0
  source    = "../generated/infra-modules/storage/onpremise/redis"
  namespace = var.external_data_plane_namespace
  redis = {
    image              = var.cache.image_name
    tag                = try(var.image_tags[var.cache.image_name], var.cache)
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
    namespace = var.external_data_plane_namespace
  }
  data = {
    list    = "Redis"
    adapter = "Redis"
  }
}
