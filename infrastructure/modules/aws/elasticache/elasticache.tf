resource "aws_elasticache_replication_group" "elasticache" {
  description                 = "Replication group for stdin and stdout elasticache cluster"
  replication_group_id        = var.name
  engine                      = var.elasticache.engine
  engine_version              = var.elasticache.engine_version
  node_type                   = var.elasticache.node_type
  port                        = 6379
  apply_immediately           = var.elasticache.apply_immediately
  multi_az_enabled            = var.elasticache.multi_az_enabled
  automatic_failover_enabled  = local.automatic_failover_enabled
  num_cache_clusters          = local.num_cache_clusters
  preferred_cache_cluster_azs = var.elasticache.preferred_cache_cluster_azs
  data_tiering_enabled        = var.elasticache.data_tiering_enabled
  at_rest_encryption_enabled  = true
  transit_encryption_enabled  = true
  kms_key_id                  = var.elasticache.encryption_keys.kms_key_id
  parameter_group_name        = aws_elasticache_parameter_group.elasticache.name
  security_group_ids          = [aws_security_group.elasticache.id]
  subnet_group_name           = aws_elasticache_subnet_group.elasticache.name
  log_delivery_configuration {
    destination      = module.slow_log.name
    destination_type = "cloudwatch-logs"
    log_format       = "json"
    log_type         = "slow-log"
  }
  log_delivery_configuration {
    destination      = module.engine_log.name
    destination_type = "cloudwatch-logs"
    log_format       = "json"
    log_type         = "engine-log"
  }
  tags = local.tags
  depends_on = [
    aws_elasticache_parameter_group.elasticache,
    aws_security_group.elasticache,
    aws_elasticache_subnet_group.elasticache,
  ]
}

resource "aws_elasticache_parameter_group" "elasticache" {
  name   = "${var.name}-config"
  family = "redis6.x"
  parameter {
    name  = "maxmemory-policy"
    value = "allkeys-lru"
  }
  tags = local.tags
}

resource "aws_security_group" "elasticache" {
  name        = "${var.name}-sg"
  description = "Allow Redis Elasticache inbound traffic on port 6379"
  vpc_id      = var.vpc.id
  ingress {
    description = "tcp from ArmoniK VPC"
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    cidr_blocks = var.vpc.cidr_blocks
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = local.tags
}

# Subnet group for Elasticache IP
resource "aws_elasticache_subnet_group" "elasticache" {
  description = "Subnet ids for IO of ArmoniK AWS Elasticache"
  name        = "${var.name}-io"
  subnet_ids  = var.vpc.subnet_ids
  tags        = local.tags
}