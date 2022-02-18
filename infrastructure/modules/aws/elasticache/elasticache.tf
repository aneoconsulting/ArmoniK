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
  tags                        = local.tags
  depends_on                  = [
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
  tags   = local.tags
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
  tags        = local.tags
}

# Subnet group for Elasticache IP
resource "aws_elasticache_subnet_group" "elasticache" {
  description = "Subnet ids for IO of ArmoniK AWS Elasticache"
  name        = "${var.name}-io"
  subnet_ids  = var.vpc.subnet_ids
  tags        = local.tags
}

# Enable cloudwatch logs
# Slow log and engine log not yet available in Terraform
module "slow_log" {
  source            = "../cloudwatch-log-group"
  name              = "/aws/elasticache/${var.name}-slow-log"
  kms_key_id        = var.elasticache.encryption_keys.log_kms_key_id
  retention_in_days = var.elasticache.log_retention_in_days
  tags              = local.tags
}

module "engine_log" {
  source            = "../cloudwatch-log-group"
  name              = "/aws/elasticache/${var.name}-engine-log"
  kms_key_id        = var.elasticache.encryption_keys.log_kms_key_id
  retention_in_days = var.elasticache.log_retention_in_days
  tags              = local.tags
}

resource "null_resource" "enable_logs" {
  provisioner "local-exec" {
    command = "aws elasticache modify-replication-group --replication-group-id ${aws_elasticache_replication_group.elasticache.id} --apply-immediately --log-delivery-configurations '[{\"LogType\":\"slow-log\",\"DestinationType\":\"cloudwatch-logs\",\"DestinationDetails\":{\"CloudWatchLogsDetails\":{\"LogGroup\":\"${module.slow_log.name}\"}},\"LogFormat\":\"json\",\"Enabled\":true},{\"LogType\":\"engine-log\",\"DestinationType\":\"cloudwatch-logs\",\"DestinationDetails\":{\"CloudWatchLogsDetails\":{\"LogGroup\":\"${module.engine_log.name}\"}},\"LogFormat\":\"json\",\"Enabled\":true}]'"
  }
  depends_on = [
    aws_elasticache_replication_group.elasticache,
    module.engine_log,
    module.slow_log
  ]
}

# IMA
data "aws_iam_policy_document" "elasticache_logs_policy" {
  statement {
    effect    = "Allow"
    actions   = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:PutLogEventsBatch",
      "logs:PutRetentionPolicy",
    ]
    resources = ["arn:aws:logs:*:*:*:/aws/elasticache/*"]
    principals {
      identifiers = ["elasticache.amazonaws.com"]
      type        = "Service"
    }
  }
}

resource "aws_cloudwatch_log_resource_policy" "elasticache_logs_publishing_policy" {
  policy_document = data.aws_iam_policy_document.elasticache_logs_policy.json
  policy_name     = "elasticache-logs-publishing-policy"
}
