# Current account
data "aws_caller_identity" "current" {}

# Current AWS region
data "aws_region" "current" {}

locals {
  account_id                 = data.aws_caller_identity.current.id
  region                     = data.aws_region.current.name
  tags                       = merge(var.tags, { module = "elasticache" })
  automatic_failover_enabled = (var.elasticache.multi_az_enabled ? true : var.elasticache.automatic_failover_enabled)
  num_cache_clusters         = (var.elasticache.multi_az_enabled ? (var.elasticache.num_cache_clusters < 1 ? var.elasticache.num_cache_clusters + 2 : (var.elasticache.num_cache_clusters == 1 ? var.elasticache.num_cache_clusters + 1 : var.elasticache.num_cache_clusters)) : (var.elasticache.automatic_failover_enabled ? (var.elasticache.num_cache_clusters < 1 ? var.elasticache.num_cache_clusters + 1 : var.elasticache.num_cache_clusters) : var.elasticache.num_cache_clusters))
}
