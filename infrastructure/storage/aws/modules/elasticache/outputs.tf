output "elasticache" {
  description = "AWS Elasticache object"
  value       = aws_elasticache_replication_group.elasticache
}

# Redis
output "redis_endpoint_url" {
  description = "AWS Elasticahe (Redis) endpoint urls"
  value       = {
    url  = "${aws_elasticache_replication_group.elasticache.primary_endpoint_address}:${aws_elasticache_replication_group.elasticache.port}"
    host = aws_elasticache_replication_group.elasticache.primary_endpoint_address
    port = aws_elasticache_replication_group.elasticache.port
  }
}