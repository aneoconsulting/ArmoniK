# Decrypt objects in S3
data "aws_iam_policy_document" "decrypt_s3_storage_object" {
  count = length(module.s3_os) > 0 ? 1 : 0
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
      local.s3_os_kms_key_id
    ]
  }
}

resource "aws_iam_policy" "decrypt_s3_storage_object" {
  count       = length(module.s3_os) > 0 ? 1 : 0
  name_prefix = local.iam_s3_decrypt_s3_storage_object_policy_name
  description = "Policy for alowing decryption of encrypted object in S3 ${var.eks.cluster_id}"
  policy      = data.aws_iam_policy_document.decrypt_s3_storage_object[0].json
  tags        = local.tags
}

resource "aws_iam_policy_attachment" "decrypt_s3_storage_object" {
  count      = length(module.s3_os) > 0 ? 1 : 0
  name       = "s3-encrypt-decrypt"
  policy_arn = aws_iam_policy.decrypt_s3_storage_object[0].arn
  roles      = var.eks.self_managed_worker_iam_role_names
}

# Read objects in S3
data "aws_iam_policy_document" "fullaccess_s3_storage_object" {
  count = length(module.s3_os) > 0 ? 1 : 0
  statement {
    sid = "FullAccessFromS3"
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:ListBucket",
      "s3:DeleteObject",
      "s3:PutObjectAcl",
      "s3:PutObjectTagging",
    ]
    effect = "Allow"
    resources = [
      "${module.s3_os[0].arn}/*"
    ]
  }
}

resource "aws_iam_policy" "fullaccess_s3_storage_object" {
  count       = length(module.s3_os) > 0 ? 1 : 0
  name_prefix = "s3-fullAccess-${var.eks.cluster_id}"
  description = "Policy for allowing read/write/delete object in S3 ${var.eks.cluster_id}"
  policy      = data.aws_iam_policy_document.fullaccess_s3_storage_object[0].json
  tags        = local.tags
}

resource "aws_iam_policy_attachment" "fullaccess_s3_storage_object_attachment" {
  count      = length(module.s3_os) > 0 ? 1 : 0
  name       = "s3-fullAccess-${var.eks.cluster_id}"
  policy_arn = aws_iam_policy.fullaccess_s3_storage_object[0].arn
  roles      = var.eks.self_managed_worker_iam_role_names
}