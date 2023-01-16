# Decrypt objects in S3
data "aws_iam_policy_document" "decrypt_s3_storage_object" {
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
  name_prefix = local.iam_s3_decrypt_s3_storage_object_policy_name
  description = "Policy for alowing decryption of encrypted object in S3 ${var.eks.cluster_id}"
  policy      = data.aws_iam_policy_document.decrypt_s3_storage_object.json
  tags        = local.tags
}

resource "aws_iam_role_policy_attachment" "decrypt_s3_storage_object" {
  policy_arn = aws_iam_policy.decrypt_s3_storage_object.arn
  role       = var.eks.worker_iam_role_name
}

# Read objects in S3
data "aws_iam_policy_document" "fullaccess_s3_storage_object" {
  statement {
    sid = "FullAccessFromS3"
    actions = [
        "s3:PutObject",
        "s3:GetObject",
        "s3:ListBucket",
        "s3:DeleteObject",
        "s3:PutObjectAcl",
        "s3:PutObjectTagging",
        "S3:*"
    ]
    effect = "Allow"
    resources = [
      "${module.s3_os.arn}/*"
    ]
  }
}

resource "aws_iam_policy" "fullaccess_s3_storage_object" {
  name_prefix = "s3-fullAccess-${var.eks.cluster_id}"
  description = "Policy for allowing read/write/delete object in S3 ${var.eks.cluster_id}"
  policy      = data.aws_iam_policy_document.fullaccess_s3_storage_object.json
  tags        = local.tags
}

resource "aws_iam_role_policy_attachment" "fullaccess_s3_storage_object_attachment" {
  policy_arn = aws_iam_policy.fullaccess_s3_storage_object.arn
  role       = var.eks.worker_iam_role_name
}