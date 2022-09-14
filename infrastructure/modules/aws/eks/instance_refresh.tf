# Based on the official aws-node-termination-handler setup guide at https://github.com/aws/aws-node-termination-handler#infrastructure-setup
resource "helm_release" "aws_node_termination_handler" {
  name      = "armonik-aws-node-termination-handler"
  namespace = "kube-system"
  chart     = "aws-node-termination-handler"
  #repository       = "https://aws.github.io/eks-charts"
  repository       = "${path.module}/charts"
  version          = "0.17.0"
  create_namespace = true

  set {
    name  = "awsRegion"
    value = local.region
  }
  set {
    name  = "logLevel"
    value = "debug"
  }
  set {
    name  = "enableSpotInterruptionDraining"
    value = "true"
  }
  set {
    name  = "serviceAccount.name"
    value = "aws-node-termination-handler"
  }
  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = module.aws_node_termination_handler_role.iam_role_arn
    type  = "string"
  }
  set {
    name  = "image.repository"
    value = var.eks.docker_images.instance_refresh.image
  }
  set {
    name  = "image.tag"
    value = var.eks.docker_images.instance_refresh.tag
  }
  /*set {
    name  = "enableSqsTerminationDraining"
    value = "true"
  }

  set {
    name  = "queueURL"
    value = module.aws_node_termination_handler_sqs.sqs_queue_id
  }*/

  values = [
    yamlencode(local.node_selector),
    yamlencode(local.tolerations)
  ]
  depends_on = [
    module.eks,
    null_resource.update_kubeconfig
  ]
}

module "aws_node_termination_handler_role" {
  source                        = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version                       = "4.1.0"
  create_role                   = true
  role_description              = "IRSA role for ANTH, cluster ${var.name}"
  role_name_prefix              = var.name
  provider_url                  = replace(module.eks.cluster_oidc_issuer_url, "https://", "")
  role_policy_arns              = [aws_iam_policy.aws_node_termination_handler.arn]
  oidc_fully_qualified_subjects = ["system:serviceaccount:kube-system:aws-node-termination-handler"]
  depends_on                    = [module.eks]
}

resource "aws_iam_policy" "aws_node_termination_handler" {
  name   = local.ima_aws_node_termination_handler_name
  policy = data.aws_iam_policy_document.aws_node_termination_handler.json
  tags   = local.tags
}

data "aws_iam_policy_document" "aws_node_termination_handler" {
  statement {
    effect = "Allow"
    actions = [
      "ec2:DescribeInstances",
      "autoscaling:DescribeAutoScalingInstances",
      "autoscaling:DescribeTags",
    ]
    resources = [
      "*",
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "autoscaling:CompleteLifecycleAction",
    ]
    resources = module.eks.workers_asg_arns
  }
  /*statement {
    effect    = "Allow"
    actions   = [
      "sqs:DeleteMessage",
      "sqs:ReceiveMessage"
    ]
    resources = [
      module.aws_node_termination_handler_sqs.sqs_queue_arn
    ]
  }*/
}

resource "aws_cloudwatch_event_rule" "aws_node_termination_handler_asg" {
  name        = local.aws_node_termination_handler_asg_name
  description = "Node termination event rule"
  event_pattern = jsonencode(
    {
      "source" : [
        "aws.autoscaling"
      ],
      "detail-type" : [
        "EC2 Instance-terminate Lifecycle Action"
      ]
      "resources" : module.eks.workers_asg_arns
    }
  )
  tags = local.tags
}

resource "aws_cloudwatch_event_rule" "aws_node_termination_handler_spot" {
  name        = local.aws_node_termination_handler_spot_name
  description = "Node termination event rule"
  event_pattern = jsonencode(
    {
      "source" : [
        "aws.ec2"
      ],
      "detail-type" : [
        "EC2 Spot Instance Interruption Warning"
      ]
      "resources" : module.eks.workers_asg_arns
    }
  )
  tags = local.tags
}

# Creating the lifecycle-hook outside of the ASG resource's `initial_lifecycle_hook`
# ensures that node termination does not require the lifecycle action to be completed,
# and thus allows the ASG to be destroyed cleanly.
resource "aws_autoscaling_lifecycle_hook" "aws_node_termination_handler" {
  count                  = length(module.eks.workers_asg_names)
  name                   = "aws-node-termination-handler"
  autoscaling_group_name = module.eks.workers_asg_names[count.index]
  lifecycle_transition   = "autoscaling:EC2_INSTANCE_TERMINATING"
  heartbeat_timeout      = 300
  default_result         = "CONTINUE"
}


/*
data "aws_iam_policy_document" "aws_node_termination_handler_events" {
  statement {
    effect    = "Allow"
    principals {
      type        = "Service"
      identifiers = [
        "events.amazonaws.com",
        "sqs.amazonaws.com",
      ]
    }
    actions   = [
      "sqs:SendMessage",
    ]
    resources = [
      "arn:aws:sqs:${var.region}:${data.aws_caller_identity.current.account_id}:${local.cluster_name}",
    ]
  }
}

module "aws_node_termination_handler_sqs" {
  source                    = "terraform-aws-modules/sqs/aws"
  version                   = "~> 3.0.0"
  name                      = local.cluster_name
  message_retention_seconds = 300
  policy                    = data.aws_iam_policy_document.aws_node_termination_handler_events.json
}

resource "aws_cloudwatch_event_target" "aws_node_termination_handler_asg" {
  target_id = "${local.cluster_name}-asg-termination"
  rule      = aws_cloudwatch_event_rule.aws_node_termination_handler_asg.name
  arn       = module.aws_node_termination_handler_sqs.sqs_queue_arn
}

resource "aws_cloudwatch_event_target" "aws_node_termination_handler_spot" {
  target_id = "${local.cluster_name}-spot-termination"
  rule      = aws_cloudwatch_event_rule.aws_node_termination_handler_spot.name
  arn       = module.aws_node_termination_handler_sqs.sqs_queue_arn
}
*/