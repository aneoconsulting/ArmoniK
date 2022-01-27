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
      "mq:*",
      "elasticache:*",
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
