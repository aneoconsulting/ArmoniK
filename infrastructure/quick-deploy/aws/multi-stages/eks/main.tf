# AWS KMS
module "kms" {
  count  = can(coalesce(var.eks.encryption_keys.cluster_log_kms_key_id)) && can(coalesce(var.eks.encryption_keys.cluster_encryption_config)) && can(coalesce(var.eks.encryption_keys.ebs_kms_key_id)) ? 0 : 1
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

# AWS EKS
module "eks" {
  source          = "../generated/infra-modules/kubernetes/aws/eks"
  profile         = var.profile
  tags            = local.tags
  name            = local.cluster_name
  node_selector   = var.node_selector
  kubeconfig_file = abspath(var.kubeconfig_file)

  vpc_id                 = local.vpc.id
  vpc_private_subnet_ids = local.vpc.private_subnet_ids
  vpc_pods_subnet_ids    = local.vpc.pods_subnet_ids

  cluster_autoscaler_image                                 = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.region}.amazonaws.com/${local.suffix}/${var.eks.docker_images.cluster_autoscaler.image}"
  cluster_autoscaler_tag                                   = var.eks.docker_images.cluster_autoscaler.tag
  cluster_autoscaler_expander                              = var.eks.cluster_autoscaler.expander
  cluster_autoscaler_scale_down_enabled                    = var.eks.cluster_autoscaler.scale_down_enabled
  cluster_autoscaler_min_replica_count                     = var.eks.cluster_autoscaler.min_replica_count
  cluster_autoscaler_scale_down_utilization_threshold      = var.eks.cluster_autoscaler.scale_down_utilization_threshold
  cluster_autoscaler_scale_down_non_empty_candidates_count = var.eks.cluster_autoscaler.scale_down_non_empty_candidates_count
  cluster_autoscaler_max_node_provision_time               = var.eks.cluster_autoscaler.max_node_provision_time
  cluster_autoscaler_scan_interval                         = var.eks.cluster_autoscaler.scan_interval
  cluster_autoscaler_scale_down_delay_after_add            = var.eks.cluster_autoscaler.scale_down_delay_after_add
  cluster_autoscaler_scale_down_delay_after_delete         = var.eks.cluster_autoscaler.scale_down_delay_after_delete
  cluster_autoscaler_scale_down_delay_after_failure        = var.eks.cluster_autoscaler.scale_down_delay_after_failure
  cluster_autoscaler_scale_down_unneeded_time              = var.eks.cluster_autoscaler.scale_down_unneeded_time
  cluster_autoscaler_skip_nodes_with_system_pods           = var.eks.cluster_autoscaler.skip_nodes_with_system_pods
  cluster_autoscaler_version                               = var.eks.cluster_autoscaler.version
  cluster_autoscaler_repository                            = var.eks.cluster_autoscaler.repository
  cluster_autoscaler_namespace                             = var.eks.cluster_autoscaler.namespace

  instance_refresh_image      = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.region}.amazonaws.com/${local.suffix}/${var.eks.docker_images.instance_refresh.image}"
  instance_refresh_tag        = var.eks.docker_images.instance_refresh.tag
  instance_refresh_version    = var.eks.instance_refresh.version
  instance_refresh_repository = var.eks.instance_refresh.repository
  instance_refresh_namespace  = var.eks.instance_refresh.namespace

  cluster_log_kms_key_id    = try(coalesce(var.eks.encryption_keys.cluster_log_kms_key_id), module.kms[0].key_arn)
  cluster_encryption_config = try(coalesce(var.eks.encryption_keys.cluster_encryption_config), module.kms[0].key_arn)
  ebs_kms_key_id            = try(coalesce(var.eks.encryption_keys.ebs_kms_key_id), module.kms[0].key_arn)

  cluster_version                      = var.eks.cluster_version
  cluster_endpoint_private_access      = var.eks.cluster_endpoint_private_access
  cluster_endpoint_public_access       = var.eks.cluster_endpoint_public_access
  cluster_endpoint_public_access_cidrs = var.eks.cluster_endpoint_public_access_cidrs
  cluster_log_retention_in_days        = var.eks.cluster_log_retention_in_days

  map_roles_groups         = var.eks.map_roles
  map_users_groups         = var.eks.map_users
  eks_managed_node_groups  = var.eks_managed_node_groups
  self_managed_node_groups = var.self_managed_node_groups
  fargate_profiles         = var.fargate_profiles
}
