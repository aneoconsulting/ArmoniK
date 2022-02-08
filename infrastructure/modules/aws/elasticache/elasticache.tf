resource "aws_elasticache_replication_group" "elasticache" {
  replication_group_description = "Replication group for stdin and stdout elasticache cluster"
  replication_group_id          = var.name
  engine                        = var.elasticache.engine
  engine_version                = var.elasticache.engine_version
  node_type                     = var.elasticache.node_type
  port                          = 6379
  at_rest_encryption_enabled    = true
  transit_encryption_enabled    = true
  kms_key_id                    = var.elasticache.encryption_keys.kms_key_id
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

# Subnet group for Elasticache IP
resource "aws_elasticache_subnet_group" "elasticache" {
  description = "Subnet ids for IO of ArmoniK AWS Elasticache"
  name        = "${var.name}-io"
  subnet_ids  = var.elasticache.vpc.subnet_ids
  tags        = local.tags
}

# Enable cloudwatch logs
# Slow log and engine log not yet available in Terraform
resource "aws_cloudwatch_log_group" "slow_log" {
  name              = "/aws/elasticache/${var.name}-slow-log"
  kms_key_id        = var.elasticache.encryption_keys.log_kms_key_id
  retention_in_days = var.elasticache.log_retention_in_days
  tags              = local.tags
}

resource "aws_cloudwatch_log_group" "engine_log" {
  name              = "/aws/elasticache/${var.name}-engine-log"
  kms_key_id        = var.elasticache.encryption_keys.log_kms_key_id
  retention_in_days = var.elasticache.log_retention_in_days
  tags              = local.tags
}

resource "null_resource" "enable_logs" {
  provisioner "local-exec" {
    command = "aws elasticache modify-replication-group --replication-group-id ${aws_elasticache_replication_group.elasticache.id} --apply-immediately --log-delivery-configurations '[{\"LogType\":\"slow-log\",\"DestinationType\":\"cloudwatch-logs\",\"DestinationDetails\":{\"CloudWatchLogsDetails\":{\"LogGroup\":\"${aws_cloudwatch_log_group.slow_log.name}\"}},\"LogFormat\":\"json\",\"Enabled\":true},{\"LogType\":\"engine-log\",\"DestinationType\":\"cloudwatch-logs\",\"DestinationDetails\":{\"CloudWatchLogsDetails\":{\"LogGroup\":\"${aws_cloudwatch_log_group.engine_log.name}\"}},\"LogFormat\":\"json\",\"Enabled\":true}]'"
  }
  depends_on = [
    aws_elasticache_replication_group.elasticache
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
