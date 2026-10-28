# One customer managed key for the EKS secrets, the logs, the object storage and RDS. Node volumes
# keep the AWS managed EBS key: a customer key there needs grants for the autoscaling service-linked
# role (managed node groups) and for the Karpenter controller, for no gain in a quick deploy.
module "kms" {
  source  = "terraform-aws-modules/kms/aws"
  version = "~> 4.2"

  description             = "ArmoniK ${local.name}"
  aliases                 = [local.name]
  deletion_window_in_days = 7
  enable_key_rotation     = true

  key_statements = [
    {
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
      condition = [{
        test     = "ArnLike"
        variable = "kms:EncryptionContext:aws:logs:arn"
        values   = ["arn:${local.partition}:logs:${var.region}:${local.account_id}:log-group:*"]
      }]
    },
  ]
}
