resource "kubernetes_secret" "redis_endpoints" {
  metadata {
    name      = "redis-endpoints"
    namespace = var.namespace
  }
  data = {
    host = aws_elasticache_replication_group.elasticache.primary_endpoint_address
    port = aws_elasticache_replication_group.elasticache.port
    url  = "${aws_elasticache_replication_group.elasticache.primary_endpoint_address}:${aws_elasticache_replication_group.elasticache.port}"
  }
}