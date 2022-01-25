resource "aws_elasticache_cluster" "example" {
  cluster_id           = "cluster-example"
  engine               = "redis"
  node_type            = "cache.m4.large"
  num_cache_nodes      = var.redis.replicas
  parameter_group_name = "default.redis6.x"
  engine_version       = "6.2.5"
  port                 = var.redis.port
}