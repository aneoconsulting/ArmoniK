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
  name_prefix = "send-logs-from-fluent-bit-to-cloudwatch-${var.eks.cluster_id}"
  description = "Policy for allowing send logs from fluent-bit  ${var.eks.cluster_id} to cloudwatch"
  policy      = data.aws_iam_policy_document.send_logs_from_fluent_bit_to_cloudwatch_document.0.json
  tags        = local.tags
}

resource "aws_iam_role_policy_attachment" "send_logs_from_fluent_bit_to_cloudwatch_attachment" {
  count      = (local.cloudwatch_enabled ? 1 : 0)
  policy_arn = aws_iam_policy.send_logs_from_fluent_bit_to_cloudwatch_policy.0.arn
  role       = var.eks.worker_iam_role_name
}

# Decrypt objects in S3
data "aws_iam_policy_document" "decrypt_s3_logs" {
  count = length(module.s3_logs) > 0 ? 1 : 0
  statement {
    sid = "KMSAccess"
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]
    effect = "Allow"
    resources = [
      local.s3_logs_kms_key_id
    ]
  }
}

resource "aws_iam_policy" "decrypt_s3_logs" {
  count       = length(module.s3_logs) > 0 ? 1 : 0
  name_prefix = local.iam_s3_logs_decrypt_s3_policy_name
  description = "Policy for alowing decryption of encrypted object in S3 ${var.eks.cluster_id}"
  policy      = data.aws_iam_policy_document.decrypt_s3_logs[0].json
  tags        = local.tags
}

resource "aws_iam_role_policy_attachment" "decrypt_s3_logs" {
  count      = length(module.s3_logs) > 0 ? 1 : 0
  policy_arn = aws_iam_policy.decrypt_s3_logs[0].arn
  role       = var.eks.worker_iam_role_name
}

# Write objects in S3
data "aws_iam_policy_document" "writeaccess_s3_logs" {
  count = length(module.s3_logs) > 0 ? 1 : 0
  statement {
    sid = "WriteAccessInS3"
    actions = [
      "s3:PutObject",
    ]
    effect = "Allow"
    resources = [
      "${module.s3_logs[0].arn}/*"
    ]
  }
}

resource "aws_iam_policy" "writeaccess_s3_logs" {
  count       = length(module.s3_logs) > 0 ? 1 : 0
  name_prefix = "s3-writeaccess-${var.eks.cluster_id}"
  description = "Policy for allowing read/write/delete object in S3 ${var.eks.cluster_id}"
  policy      = data.aws_iam_policy_document.writeaccess_s3_logs[0].json
  tags        = local.tags
}

resource "aws_iam_role_policy_attachment" "writeaccess_s3_logs_attachment" {
  count      = length(module.s3_logs) > 0 ? 1 : 0
  policy_arn = aws_iam_policy.writeaccess_s3_logs[0].arn
  role       = var.eks.worker_iam_role_name
}