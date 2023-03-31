resource "aws_s3_bucket" "s3_bucket" {
  bucket        = var.name
  force_destroy = true
  tags          = local.tags
}

resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.s3_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_acl" "acl" {
  bucket = aws_s3_bucket.s3_bucket.id
  acl    = "private"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "encryption" {
  bucket = aws_s3_bucket.s3_bucket.bucket
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = var.s3.sse_algorithm
      kms_master_key_id = var.s3.kms_key_id
    }
  }
}

data "aws_iam_policy_document" "deny_insecure_transport" {
  count = (var.s3.attach_deny_insecure_transport_policy ? 1 : 0)
  statement {
    sid    = "denyInsecureTransport"
    effect = "Deny"
    actions = [
      "s3:*",
    ]
    resources = [
      aws_s3_bucket.s3_bucket.arn,
      "${aws_s3_bucket.s3_bucket.arn}/*",
    ]
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values = [
        "false"
      ]
    }
  }
}

data "aws_iam_policy_document" "require_latest_tls" {
  count = (var.s3.attach_require_latest_tls_policy ? 1 : 0)
  statement {
    sid    = "denyOutdatedTLS"
    effect = "Deny"
    actions = [
      "s3:*",
    ]
    resources = [
      aws_s3_bucket.s3_bucket.arn,
      "${aws_s3_bucket.s3_bucket.arn}/*",
    ]
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    condition {
      test     = "NumericLessThan"
      variable = "s3:TlsVersion"
      values = [
        "1.2"
      ]
    }
  }
}

data "aws_iam_policy_document" "combined" {
  count = (local.attach_policy ? 1 : 0)
  source_policy_documents = compact([
    var.s3.attach_require_latest_tls_policy ? data.aws_iam_policy_document.require_latest_tls[0].json : "",
    var.s3.attach_deny_insecure_transport_policy ? data.aws_iam_policy_document.deny_insecure_transport[0].json : "",
    var.s3.attach_policy ? var.s3.policy : ""
  ])
}

resource "aws_s3_bucket_policy" "s3_bucket" {
  count  = (local.attach_policy ? 1 : 0)
  bucket = aws_s3_bucket.s3_bucket.id
  policy = data.aws_iam_policy_document.combined[0].json
}

resource "aws_s3_bucket_public_access_block" "s3_bucket" {
  # Chain resources (s3_bucket -> s3_bucket_policy -> s3_bucket_public_access_block)
  # to prevent "A conflicting conditional operation is currently in progress against this resource."
  # Ref: https://github.com/hashicorp/terraform-provider-aws/issues/7628

  count                   = (var.s3.attach_public_policy ? 1 : 0)
  bucket                  = local.attach_policy ? aws_s3_bucket_policy.s3_bucket.0.id : aws_s3_bucket.s3_bucket.id
  block_public_acls       = var.s3.block_public_acls
  block_public_policy     = var.s3.block_public_policy
  ignore_public_acls      = var.s3.ignore_public_acls
  restrict_public_buckets = var.s3.restrict_public_buckets
}

# resource "aws_s3_bucket_lifecycle_configuration" "s3_logs" {
#   count = var.s3.retention_in_days != null ? 1 : 0
#   bucket = aws_s3_bucket.s3_bucket.id

#   rule {
#     id = "rule-1"
#     expiration {
#       days = var.s3.retention_in_days
#     }
#     status = "Enabled"
#   }
# }