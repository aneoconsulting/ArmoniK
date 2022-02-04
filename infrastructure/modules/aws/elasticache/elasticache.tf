resource "aws_elasticache_replication_group" "elasticache" {
  replication_group_description = "Replication group for stdin and stdout elasticache cluster"
  replication_group_id          = var.name
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

resource "aws_elasticache_parameter_group" "elasticache" {
  name   = "${var.name}-config"
  family = "redis6.x"
  parameter {
    name  = "maxmemory-policy"
    value = "allkeys-lru"
  }
  tags   = local.tags
}

resource "aws_security_group" "elasticache" {
  name        = "${var.name}-sg"
  description = "Allow Redis Elasticache inbound traffic on port 6379"
  vpc_id      = var.elasticache.vpc.id
  ingress {
    description = "tcp from ArmoniK VPC"
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    cidr_blocks = var.elasticache.vpc.cidr_blocks
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags        = local.tags
}

resource "aws_elasticache_subnet_group" "elasticache" {
  description = "Subnet ids for IO of ArmoniK AWS Elasticache"
  name        = "${var.name}-io"
  subnet_ids  = var.elasticache.vpc.subnet_ids
  tags        = local.tags
}