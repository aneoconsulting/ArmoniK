resource "aws_elasticache_parameter_group" "elasticache" {
  name   = "armonik-elasticache-config-${var.elasticache.tag}"
  family = "redis6.x"
  parameter {
    name  = "maxmemory-policy"
    value = "allkeys-lru"
  }
  tags   = local.tags
}