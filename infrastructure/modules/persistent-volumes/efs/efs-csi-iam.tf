# Allow EKS and the driver to interact with EFS
data "aws_iam_policy_document" "efs_csi_driver" {
  statement {
    sid = "Describe"
    actions = [
      "elasticfilesystem:DescribeAccessPoints",
      "elasticfilesystem:DescribeFileSystems",
      "elasticfilesystem:DescribeMountTargets",
      "ec2:DescribeAvailabilityZones"
    ]
    effect    = "Allow"
    resources = ["*"]
  }
  statement {
    sid = "Create"
    actions = [
      "elasticfilesystem:CreateAccessPoint"
    ]
    effect    = "Allow"
    resources = ["*"]
    condition {
      test     = "StringLike"
      values   = [true]
      variable = "aws:RequestTag/efs.csi.aws.com/cluster"
    }
  }
  statement {
    sid = "Delete"
    actions = [
      "elasticfilesystem:DeleteAccessPoint"
    ]
    effect    = "Allow"
    resources = ["*"]
    condition {
      test     = "StringEquals"
      values   = [true]
      variable = "aws:ResourceTag/efs.csi.aws.com/cluster"
    }
  }
}

resource "aws_iam_policy" "efs_csi_driver" {
  name_prefix = local.efs_csi_name
  description = "Policy to allow EKS and the driver to interact with EFS"
  policy      = data.aws_iam_policy_document.efs_csi_driver.json
  tags        = local.tags
}

resource "aws_iam_openid_connect_provider" "eks_oidc" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = concat([data.tls_certificate.eks.certificates.0.sha1_fingerprint], local.oidc_thumbprint_list)
  url             = var.eks_issuer
}

resource "aws_iam_role" "efs_csi_driver" {
  name = local.efs_csi_name
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = local.oidc_arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            #"${local.oidc_url}:aud" = "sts.amazonaws.com"
            "${local.oidc_url}:sub" = "system:serviceaccount:${local.efs_csi_namespace}:efs-csi-driver"
          }
        }
      }
    ]
  })
  tags       = local.tags
  depends_on = [aws_iam_openid_connect_provider.eks_oidc]
}

resource "aws_iam_role_policy_attachment" "efs_csi_driver" {
  policy_arn = aws_iam_policy.efs_csi_driver.arn
  role       = aws_iam_role.efs_csi_driver.name
}

resource "kubernetes_service_account" "efs_csi_driver" {
  metadata {
    name = "efs-csi-driver"
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.efs_csi_driver.arn
    }
    namespace = local.efs_csi_namespace
  }
}