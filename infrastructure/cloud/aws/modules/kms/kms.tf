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
  tags                     = local.tags
}

# KMS alis
resource "aws_kms_alias" "kms_alias" {
  name          = "alias/${var.tag}-${var.kms.name}"
  target_key_id = aws_kms_key.kms.id
}

# KMS Policy
data "aws_iam_policy_document" "kms_policy" {
  statement {
    sid       = ""
    effect    = "Allow"
    principals {
      identifiers = ["arn:aws:iam::${var.account.id}:root"]
      type        = "AWS"
    }
    actions   = ["kms:*"]
    resources = ["*"]
  }
  statement {
    sid       = "Supported resources"
    effect    = "Allow"
    principals {
      identifiers = [var.account.id]
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
        "ec2.${var.region}.amazonaws.com",
        "s3.${var.region}.amazonaws.com",
        "sqs.${var.region}.amazonaws.com",
        "dynamodb.${var.region}.amazonaws.com",
        "ecr.${var.region}.amazonaws.com",
        "eks.${var.region}.amazonaws.com",
        "elasticache.${var.region}.amazonaws.com",
        "dax.${var.region}.amazonaws.com",
        "elasticfilesystem.${var.region}.amazonaws.com",
        "mq.${var.region}.amazonaws.com",
        "rds.${var.region}.amazonaws.com"
      ]
      variable = "kms:ViaService"
    }
  }
  statement {
    sid       = "Logs"
    effect    = "Allow"
    principals {
      identifiers = ["logs.${var.region}.amazonaws.com"]
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
      values   = ["arn:aws:logs:${var.region}:${var.account.id}:*:*"]
      variable = "kms:EncryptionContext:aws:logs:arn"
    }
  }
  statement {
    sid       = "Autoscaling"
    effect    = "Allow"
    principals {
      identifiers = [
        "arn:aws:iam::${var.account.id}:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling"
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
        "arn:aws:iam::${var.account.id}:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling"
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