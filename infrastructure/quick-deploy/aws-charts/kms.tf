# One customer managed key for the EKS secrets and logs, the VPC flow logs and Aurora (storage, Performance Insights,
# credentials secret). Node volumes keep the AWS managed EBS key: a customer key there needs grants for the
# autoscaling service-linked role and for Karpenter, for no gain here. The object storage uses SSE-S3 (storage.tf).
module "kms" {
  source = "git::https://github.com/aneoconsulting/ArmoniK.Infra.git//security/aws/kms?ref=dw/aws-charts-modules"

  name                    = local.name
  region                  = var.region
  description             = "ArmoniK ${local.name}"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  key_statements = {
    cloudwatch_logs = {
      sid = "CloudWatchLogs"
      actions = [
        "kms:Encrypt*",
        "kms:Decrypt*",
        "kms:ReEncrypt*",
        "kms:GenerateDataKey*",
        "kms:Describe*",
      ]
      resources = ["*"]
      principals = [{
        type        = "Service"
        identifiers = ["logs.${var.region}.amazonaws.com"]
      }]
      conditions = [{
        test     = "ArnLike"
        variable = "kms:EncryptionContext:aws:logs:arn"
        values   = ["arn:${local.partition}:logs:${var.region}:${local.account_id}:log-group:*"]
      }]
    }
  }

  tags = local.tags
}
