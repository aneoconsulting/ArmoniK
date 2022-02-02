resource "aws_elasticache_replication_group" "elasticache" {
  replication_group_description = "Replication group for stdin and stdout elasticache cluster"
  replication_group_id          = "armonik-elasticache-${var.elasticache.tag}"
  engine                        = var.elasticache.engine
  engine_version                = var.elasticache.engine_version
  node_type                     = var.elasticache.node_type
  port                          = 6379
  at_rest_encryption_enabled    = true
  transit_encryption_enabled    = true
  kms_key_id                    = var.elasticache.kms_key_id
  multi_az_enabled              = var.elasticache.multi_az_enabled
  parameter_group_name          = aws_elasticache_parameter_group.elasticache.name
  security_group_ids            = [aws_security_group.elasticache.id]
  subnet_group_name             = aws_elasticache_subnet_group.elasticache.name
  cluster_mode {
    replicas_per_node_group = var.elasticache.cluster_mode.replicas_per_node_group
    num_node_groups         = var.elasticache.cluster_mode.num_node_groups
  }
  automatic_failover_enabled    = (var.elasticache.cluster_mode.replicas_per_node_group >= 1 && var.elasticache.cluster_mode.num_node_groups >= 1)
  tags                          = local.tags
  depends_on                    = [
    aws_elasticache_parameter_group.elasticache,
    aws_security_group.elasticache,
    aws_elasticache_subnet_group.elasticache
  ]
}