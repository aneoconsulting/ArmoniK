# AWS KMS
module "kms" {
  count  = can(coalesce(var.vpc.flow_log_cloudwatch_log_group_kms_key_id)) ? 0 : 1
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

# AWS VPC
module "vpc" {
  source                                          = "../generated/infra-modules/networking/aws/vpc"
  name                                            = local.vpc_name
  eks_name                                        = local.cluster_name
  cidr                                            = var.vpc.main_cidr_block
  private_subnets                                 = var.vpc.cidr_block_private
  public_subnets                                  = var.vpc.cidr_block_public
  pod_subnets                                     = var.vpc.pod_cidr_block_private
  flow_log_cloudwatch_log_group_kms_key_id        = try(module.kms[0].key_arn, var.vpc.flow_log_cloudwatch_log_group_kms_key_id)
  flow_log_cloudwatch_log_group_retention_in_days = var.vpc.flow_log_cloudwatch_log_group_retention_in_days
  tags                                            = local.tags
}
