# Current account
data "aws_caller_identity" "current" {}

# Current AWS region
data "aws_region" "current" {}

# Available zones
data "aws_availability_zones" "available" {}

# Random string
resource "random_string" "random_resources" {
  length  = 5
  special = false
  upper   = false
  number  = true
}

locals {
  account_id                                           = data.aws_caller_identity.current.id
  region                                               = data.aws_region.current.name
  tags                                                 = merge({ module = "eks" }, var.tags)
  iam_worker_autoscaling_policy_name                   = "eks-worker-autoscaling-${module.eks.cluster_id}"
  iam_worker_assume_role_agent_permissions_policy_name = "eks-worker-assume-agent-${module.eks.cluster_id}"
  ima_aws_node_termination_handler_name                = "${var.name}-aws-node-termination-handler-${random_string.random_resources.result}"
  aws_node_termination_handler_asg_name                = "${var.name}-asg-termination"
  aws_node_termination_handler_spot_name               = "${var.name}-spot-termination"

  # Custom ENI
  subnets = {
    subnets = [
      for index, id in var.vpc.pods_subnet_ids : {
        subnet_id          = id
        az_name            = element(data.aws_availability_zones.available.names, index)
        security_group_ids = [module.eks.worker_security_group_id]
      }
    ]
  }

  # Node selector
  node_selector_keys   = keys(var.node_selector)
  node_selector_values = values(var.node_selector)
  node_selector = {
    nodeSelector = var.node_selector
  }
  tolerations = {
    tolerations = [
      for index in range(0, length(local.node_selector_keys)) : {
        key      = local.node_selector_keys[index]
        operator = "Equal"
        value    = local.node_selector_values[index]
        effect   = "NoSchedule"
      }
    ]
  }

  # Patch coredns
  patch_coredns_spec = {
    spec = {
      template = {
        spec = {
          nodeSelector = var.node_selector
          tolerations = [
            for index in range(0, length(local.node_selector_keys)) : {
              key      = local.node_selector_keys[index]
              operator = "Equal"
              value    = local.node_selector_values[index]
              effect   = "NoSchedule"
            }
          ]
        }
      }
    }
  }

  # EKS worker groups
  eks_worker_group = concat([
    for index in range(0, length(var.eks_worker_groups)) :
    merge(var.eks_worker_groups[index], {
      root_encrypted                       = true
      root_kms_key_id                      = var.eks.encryption_keys.ebs_kms_key_id
      additional_userdata                  = <<-EOT
      echo fs.inotify.max_user_instances=8192 | sudo tee -a /etc/sysctl.conf && sudo sysctl -p
    EOT
      metadata_http_endpoint               = "enabled"  # The state of the metadata service: enabled, disabled.
      metadata_http_tokens                 = "required" # If session tokens are required: optional, required.
      metadata_http_put_response_hop_limit = 2
      # The desired HTTP PUT response hop limit for instance metadata requests.
      tags = [
        {
          key                 = "k8s.io/cluster-autoscaler/enabled"
          propagate_at_launch = true
          value               = true
        },
        {
          key                 = "k8s.io/cluster-autoscaler/${var.name}"
          propagate_at_launch = true
          value               = true
        },
        {
          key                 = "aws-node-termination-handler/managed"
          value               = true
          propagate_at_launch = true
        }
      ]
    })
    ], [
    for index in range(0, length(var.eks_operational_worker_groups)) :
    merge(var.eks_operational_worker_groups[index], {
      root_encrypted                       = true
      root_kms_key_id                      = var.eks.encryption_keys.ebs_kms_key_id
      additional_userdata                  = <<-EOT
      echo fs.inotify.max_user_instances=8192 | sudo tee -a /etc/sysctl.conf && sudo sysctl -p
    EOT
      metadata_http_endpoint               = "enabled"  # The state of the metadata service: enabled, disabled.
      metadata_http_tokens                 = "required" # If session tokens are required: optional, required.
      metadata_http_put_response_hop_limit = 2
    })
  ])
}
