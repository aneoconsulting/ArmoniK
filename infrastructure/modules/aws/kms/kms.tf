# Key Management Service
resource "aws_kms_key" "kms" {
  description              = "KMS to encrypt/decrypt data in ArmoniK"
  customer_master_key_spec = "SYMMETRIC_DEFAULT"
  key_usage                = "ENCRYPT_DECRYPT"
  enable_key_rotation      = true
  deletion_window_in_days  = 7
  is_enabled               = true
  multi_region             = false
  policy                   = data.aws_iam_policy_document.kms_policy.json
  tags                     = local.tags
}

# KMS alias
resource "aws_kms_alias" "kms_alias" {
  name          = "alias/${var.name}"
  target_key_id = aws_kms_key.kms.id
}

# KMS Policy
data "aws_iam_policy_document" "kms_policy" {
  statement {
    sid       = ""
    effect    = "Allow"
    principals {
      identifiers = ["arn:aws:iam::${local.account_id}:root"]
      type        = "AWS"
    }
    actions   = ["kms:*"]
    resources = ["*"]
  }
  statement {
    sid       = "Supported resources"
    effect    = "Allow"
    principals {
      identifiers = ["arn:aws:iam::${local.account_id}:root"]
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
        "ec2.${local.region}.amazonaws.com",
        "s3.${local.region}.amazonaws.com",
        "dynamodb.${local.region}.amazonaws.com",
        "ecr.${local.region}.amazonaws.com",
        "eks.${local.region}.amazonaws.com",
        "elasticache.${local.region}.amazonaws.com",
        "mq.${local.region}.amazonaws.com",
      ]
      variable = "kms:ViaService"
    }
  }
  statement {
    sid       = "Logs"
    effect    = "Allow"
    principals {
      identifiers = ["logs.${local.region}.amazonaws.com"]
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
      values   = ["arn:aws:logs:${local.region}:${local.account_id}:*:*"]
      variable = "kms:EncryptionContext:aws:logs:arn"
    }
  }
  statement {
    sid       = "Autoscaling"
    effect    = "Allow"
    principals {
      identifiers = [
        "arn:aws:iam::${local.account_id}:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling"
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
        "arn:aws:iam::${local.account_id}:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling"
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