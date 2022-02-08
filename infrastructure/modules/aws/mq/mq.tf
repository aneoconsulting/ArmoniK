resource "aws_mq_broker" "mq" {
  broker_name             = var.name
  engine_type             = aws_mq_configuration.mq_configuration.engine_type
  engine_version          = aws_mq_configuration.mq_configuration.engine_version
  host_instance_type      = var.mq.host_instance_type
  apply_immediately       = true
  deployment_mode         = var.mq.deployment_mode
  storage_type            = var.mq.storage_type
  authentication_strategy = var.mq.authentication_strategy
  publicly_accessible     = var.mq.publicly_accessible
  security_groups         = [aws_security_group.mq.id]
  subnet_ids              = (var.mq.deployment_mode == "ACTIVE_STANDBY_MULTI_AZ" ? [
    var.mq.vpc.subnet_ids[0],
    var.mq.vpc.subnet_ids[1]
  ] : [var.mq.vpc.subnet_ids[0]])
  configuration {
    id       = aws_mq_configuration.mq_configuration.id
    revision = aws_mq_configuration.mq_configuration.latest_revision
  }
  encryption_options {
    kms_key_id        = var.mq.kms_key_id
    use_aws_owned_key = false
  }
  logs {
    audit   = true
    general = true
  }
  user {
    password       = var.mq.user.password
    username       = var.mq.user.username
    console_access = true
    groups         = []
  }
  tags                    = local.tags
}

# MQ configuration
resource "aws_mq_configuration" "mq_configuration" {
  description    = "ArmoniK ActiveMQ Configuration"
  name           = var.name
  engine_type    = var.mq.engine_type
  engine_version = var.mq.engine_version
  data           = <<DATA
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<broker xmlns="http://activemq.apache.org/schema/core">
  <plugins>
    <forcePersistencyModeBrokerPlugin persistenceFlag="true"/>
    <statisticsBrokerPlugin/>
    <timeStampingBrokerPlugin ttlCeiling="86400000" zeroExpirationOverride="86400000"/>
  </plugins>
</broker>
DATA
  tags           = local.tags
}

# MQ security group
resource "aws_security_group" "mq" {
  name        = "${var.name}-sg"
  description = "Allow Amazon MQ inbound traffic on port 5672"
  vpc_id      = var.mq.vpc.id
  ingress {
    description = "tcp from Amazon MQ"
    from_port   = 5671
    to_port     = 5671
    protocol    = "tcp"
    cidr_blocks = var.mq.vpc.cidr_blocks
  }
  ingress {
    description = "Web console for Amazon MQ"
    from_port   = 8162
    to_port     = 8162
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags        = local.tags
}

# IMA
data "aws_iam_policy_document" "mq_logs_policy" {
  statement {
    effect    = "Allow"
    actions   = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:PutLogEventsBatch",
      "logs:PutRetentionPolicy",
    ]
    resources = ["arn:aws:logs:*:*:*:/aws/amazonmq/*"]
    principals {
      identifiers = ["mq.amazonaws.com"]
      type        = "Service"
    }
  }
}

resource "aws_cloudwatch_log_resource_policy" "mq_logs_publishing_policy" {
  policy_document = data.aws_iam_policy_document.mq_logs_policy.json
  policy_name     = "mq-logs-publishing-policy"
}