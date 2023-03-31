# Send logs in cloudwatch
data "aws_iam_policy_document" "send_logs_from_fluent_bit_to_cloudwatch_document" {
  count = (local.cloudwatch_enabled ? 1 : 0)
  statement {
    sid = "SendLogsFromFluentBitToCloudWatch"
    actions = [
      "logs:CreateLogStream",
      "logs:CreateLogGroup",
      "logs:PutLogEvents",
    ]
    effect = "Allow"
    resources = [
      "arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:log-group:${local.cloudwatch_log_group_name}:*"
    ]
  }
}

resource "aws_iam_policy" "send_logs_from_fluent_bit_to_cloudwatch_policy" {
  count       = (local.cloudwatch_enabled ? 1 : 0)
  name_prefix = "send-logs-from-fluent-bit-to-cloudwatch-${var.eks.cluster_name}"
  description = "Policy for allowing send logs from fluent-bit  ${var.eks.cluster_name} to cloudwatch"
  policy      = data.aws_iam_policy_document.send_logs_from_fluent_bit_to_cloudwatch_document.0.json
  tags        = local.tags
}

resource "aws_iam_role_policy_attachment" "send_logs_from_fluent_bit_to_cloudwatch_attachment" {
  count      = (local.cloudwatch_enabled ? 1 : 0)
  policy_arn = aws_iam_policy.send_logs_from_fluent_bit_to_cloudwatch_policy.0.arn
  role       = var.eks.worker_iam_role_name
}