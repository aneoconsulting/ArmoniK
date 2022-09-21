# Put logs in cloudwatch
data "aws_iam_policy_document" "send_logs_from_fluent_bit_to_cloudwatch_document" {
  count = (local.cloudwatch_enabled ? 1 : 0)
  statement {
    sid       = "SendLogsFromFluentBitToCloudWatch"
    actions   = [
      "logs:CreateLogStream",
      "logs:CreateLogGroup",
      "logs:PutLogEvents",
    ]
    effect    = "Allow"
    resources = [
      "${local.cloudwatch_arn}:*"
    ]
  }
}

resource "aws_iam_policy" "send_logs_from_fluent_bit_to_cloudwatch_policy" {
  count       = (local.cloudwatch_enabled ? 1 : 0)
  name_prefix = "send-logs-from-fluent-bit-to-cloudwatch-${local.cloudwatch_cluster_id}"
  description = "Policy for allowing send logs from fluent-bit  ${local.cloudwatch_cluster_id} to cloudwatch"
  policy      = data.aws_iam_policy_document.send_logs_from_fluent_bit_to_cloudwatch_document.0.json
  tags        = local.cloudwatch_tags
}

resource "aws_iam_role_policy_attachment" "send_logs_from_fluent_bit_to_cloudwatch_attachment" {
  count      = (local.cloudwatch_enabled ? 1 : 0)
  policy_arn = aws_iam_policy.send_logs_from_fluent_bit_to_cloudwatch_policy.0.arn
  role       = local.cloudwatch_worker_iam_role_name
}