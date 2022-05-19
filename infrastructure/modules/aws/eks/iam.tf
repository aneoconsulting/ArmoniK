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
  name_prefix = local.iam_worker_assume_role_agent_permissions_policy_name
  description = "EKS worker node policy for agent in  cluster ${module.eks.cluster_id}"
  policy      = data.aws_iam_policy_document.worker_assume_role_agent_permissions_document.json
  tags        = local.tags
}

resource "aws_iam_role_policy_attachment" "worker_assume_role_agent_permissions_document" {
  policy_arn = aws_iam_policy.worker_assume_role_agent_permissions_policy.arn
  role       = module.eks.worker_iam_role_name
}

# SSM managed instance core
resource "aws_iam_role_policy_attachment" "ssm_agent" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = module.eks.worker_iam_role_name
}

# X-ray
resource "aws_iam_role_policy_attachment" "workers_xray_attach" {
  policy_arn = "arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess"
  role       = module.eks.worker_iam_role_name
}

# Full access S3 bucket
resource "aws_iam_role_policy_attachment" "s3_full_access" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
  role       = module.eks.worker_iam_role_name
}