# Decrypt objects in S3
data "aws_iam_policy_document" "decrypt_object_document" {
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
      local.s3_fs_kms_key_id
    ]
  }
}

resource "aws_iam_policy" "decrypt_object_policy" {
  name_prefix = local.iam_s3_decrypt_object_policy_name
  description = "Policy for alowing decryption of encrypted object in S3 ${var.eks.cluster_id}"
  policy      = data.aws_iam_policy_document.decrypt_object_document.json
  tags        = local.tags
}

resource "aws_iam_role_policy_attachment" "decrypt_object_attachment" {
  policy_arn = aws_iam_policy.decrypt_object_policy.arn
  role       = var.eks.worker_iam_role_name
}

# Read objects in S3
data "aws_iam_policy_document" "read_object_document" {
  statement {
    sid = "ReadFromS3"
    actions = [
      "s3:GetObject"
    ]
    effect = "Allow"
    resources = [
      "${module.s3_fs.arn}/*"
    ]
  }
}

resource "aws_iam_policy" "read_object_policy" {
  name_prefix = "s3-read-${var.eks.cluster_id}"
  description = "Policy for allowing read object in S3 ${var.eks.cluster_id}"
  policy      = data.aws_iam_policy_document.read_object_document.json
  tags        = local.tags
}

resource "aws_iam_role_policy_attachment" "read_object_attachment" {
  policy_arn = aws_iam_policy.read_object_policy.arn
  role       = var.eks.worker_iam_role_name
}