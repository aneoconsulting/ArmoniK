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

output "elasticache_name" {
  description = "Name of Elasticache cluster"
  value       = aws_elasticache_replication_group.elasticache.id
}

output "kms_key_id" {
  description = "ARN of KMS used for Elasticache"
  value       = aws_elasticache_replication_group.elasticache.kms_key_id
}