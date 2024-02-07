# AWS KMS
module "kms" {
  count  = can(coalesce(var.ecr.kms_key_id)) ? 0 : 1
  source = "../generated/infra-modules/security/aws/kms"
  name   = local.kms_name
  tags   = local.tags

  key_asymmetric_sign_verify_users = [
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling",
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
  ]
  key_service_users = [
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling",
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
  ]
  key_statements = [
    {
      sid = "CloudWatchLogs"
      actions = [
        "kms:Encrypt*",
        "kms:Decrypt*",
        "kms:ReEncrypt*",
        "kms:GenerateDataKey*",
        "kms:Describe*"
      ]
      resources = ["*"]

      principals = [
        {
          type        = "Service"
          identifiers = ["logs.${var.region}.amazonaws.com"]
        }
      ]

      conditions = [
        {
          test     = "ArnLike"
          variable = "kms:EncryptionContext:aws:logs:arn"
          values = [
            "arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:log-group:*",
          ]
        }
      ]
    }
  ]
}

# AWS ECR
module "ecr" {
  source       = "../generated/infra-modules/container-registry/aws/ecr"
  aws_profile  = var.profile
  kms_key_id   = try(coalesce(var.ecr.kms_key_id), module.kms[0].key_arn)
  repositories = local.repositories
  tags         = local.tags
}
