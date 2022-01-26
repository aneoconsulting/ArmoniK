# Agent permissions
data "aws_iam_policy_document" "worker_assume_role_agent_permissions_document" {
  statement {
    sid       = ""
    effect    = "Allow"
    actions   = [
      "sqs:*",
      "dynamodb:*",
      "lambda:*",
      "logs:*",
      "s3:*",
      "firehose:*",
      "cloudwatch:PutMetricData",
      "cloudwatch:GetMetricData",
      "cloudwatch:GetMetricStatistics",
      "cloudwatch:ListMetrics",
      "route53:AssociateVPCWithHostedZone"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "worker_assume_role_agent_permissions_policy" {
  name_prefix = "eks-worker-assume-agent-${module.eks.cluster_id}"
  description = "EKS worker node policy for agent in  cluster ${module.eks.cluster_id}"
  policy      = data.aws_iam_policy_document.worker_assume_role_agent_permissions_document.json
}

resource "aws_iam_role_policy_attachment" "worker_assume_role_agent_permissions_document" {
  policy_arn = aws_iam_policy.worker_assume_role_agent_permissions_policy.arn
  role       = module.eks.worker_iam_role_name
}

# Workers Auto Scaling policy
data "aws_iam_policy_document" "worker_autoscaling_document" {
  statement {
    sid       = "eksWorkerAutoscalingAll"
    effect    = "Allow"
    actions   = [
      "autoscaling:DescribeAutoScalingGroups",
      "autoscaling:DescribeAutoScalingInstances",
      "autoscaling:DescribeLaunchConfigurations",
      "autoscaling:DescribeTags",
      "ec2:DescribeLaunchTemplateVersions",
    ]
    resources = ["*"]
  }
  statement {
    sid       = "eksWorkerAutoscalingOwn"
    effect    = "Allow"
    actions   = [
      "autoscaling:SetDesiredCapacity",
      "autoscaling:TerminateInstanceInAutoScalingGroup",
      "autoscaling:UpdateAutoScalingGroup",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "worker_autoscaling_policy" {
  name_prefix = "eks-worker-autoscaling-${module.eks.cluster_id}"
  description = "EKS worker node autoscaling policy for cluster ${module.eks.cluster_id}"
  policy      = data.aws_iam_policy_document.worker_autoscaling_document.json
}

resource "aws_iam_role_policy_attachment" "workers_autoscaling_attach" {
  policy_arn = aws_iam_policy.worker_autoscaling_policy.arn
  role       = module.eks.worker_iam_role_name
}

resource "aws_iam_role_policy_attachment" "workers_xray_attach" {
  policy_arn = "arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess"
  role       = module.eks.worker_iam_role_name
}

resource "aws_iam_role_policy_attachment" "ssm_agent" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = module.eks.worker_iam_role_name
}