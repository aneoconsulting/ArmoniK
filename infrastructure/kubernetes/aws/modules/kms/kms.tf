# Key Management Service
resource "aws_kms_key" "kms" {
  description              = "KMS to encrypt/decrypt data"
  customer_master_key_spec = var.kms.customer_master_key_spec
  key_usage                = var.kms.key_usage
  enable_key_rotation      = var.kms.enable_key_rotation
  deletion_window_in_days  = var.kms.deletion_window_in_days
  is_enabled               = var.kms.is_enabled
  multi_region             = var.kms.multi_region
  policy                   = data.aws_iam_policy_document.kms_policy.json
  tags                     = merge(var.kms.tags, { resource = "KMS" })
}

# KMS alias
resource "aws_kms_alias" "kms_alias" {
  name          = "alias/${var.kms.name}"
  target_key_id = aws_kms_key.kms.id
}

# KMS Policy
data "aws_iam_policy_document" "kms_policy" {
  statement {
    sid       = ""
    effect    = "Allow"
    principals {
      identifiers = ["arn:aws:iam::${var.kms.account_id}:root"]
      type        = "AWS"
    }
    actions   = ["kms:*"]
    resources = ["*"]
  }
  statement {
    sid       = "Supported resources"
    effect    = "Allow"
    principals {
      identifiers = [var.kms.account_id]
      type        = "AWS"
    }
    actions   = [
      "kms:Encrypt*",
      "kms:Decrypt*",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:Describe*"
    ]
    resources = ["*"]
    condition {
      test     = "StringEquals"
      values   = [
        "ec2.${var.kms.region}.amazonaws.com",
        "s3.${var.kms.region}.amazonaws.com",
        "sqs.${var.kms.region}.amazonaws.com",
        "dynamodb.${var.kms.region}.amazonaws.com",
        "ecr.${var.kms.region}.amazonaws.com",
        "eks.${var.kms.region}.amazonaws.com",
        "elasticache.${var.kms.region}.amazonaws.com",
        "dax.${var.kms.region}.amazonaws.com",
        "elasticfilesystem.${var.kms.region}.amazonaws.com",
        "mq.${var.kms.region}.amazonaws.com",
        "rds.${var.kms.region}.amazonaws.com"
      ]
      variable = "kms:ViaService"
    }
  }
  statement {
    sid       = "Logs"
    effect    = "Allow"
    principals {
      identifiers = ["logs.${var.kms.region}.amazonaws.com"]
      type        = "Service"
    }
    actions   = [
      "kms:Encrypt*",
      "kms:Decrypt*",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:Describe*"
    ]
    resources = ["*"]
    condition {
      test     = "ArnEquals"
      values   = ["arn:aws:logs:${var.kms.region}:${var.kms.account_id}:*:*"]
      variable = "kms:EncryptionContext:aws:logs:arn"
    }
  }
  statement {
    sid       = "Autoscaling"
    effect    = "Allow"
    principals {
      identifiers = [
        "arn:aws:iam::${var.kms.account_id}:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling"
      ]
      type        = "AWS"
    }
    actions   = [
      "kms:Encrypt*",
      "kms:Decrypt*",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:Describe*"
    ]
    resources = ["*"]
  }
  statement {
    sid       = ""
    effect    = "Allow"
    principals {
      identifiers = [
        "arn:aws:iam::${var.kms.account_id}:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling"
      ]
      type        = "AWS"
    }
    actions   = ["kms:CreateGrant"]
    resources = ["*"]
    condition {
      test     = "Bool"
      values   = [true]
      variable = "kms:GrantIsForAWSResource"
    }
  }
}