# EKS Pod Identity roles of the control and compute planes. The charts create the service accounts.
module "armonik_identity" {
  source   = "git::https://github.com/aneoconsulting/ArmoniK.Infra.git//service-account/aws?ref=dw/aws-charts-modules"
  for_each = local.service_accounts

  prefix                 = local.name
  name                   = each.value
  namespace              = var.namespace
  create_service_account = false
  pod_identity           = true
  cluster_name           = terraform_data.system_nodes.output.cluster_name
  oidc_provider_arn      = module.eks.aws_eks_module.oidc_provider_arn
  oidc_issuer_url        = module.eks.issuer
  tags                   = local.tags
}

# Exactly the calls the Core S3 and SQS adapters make. Here rather than through the s3 and sqs modules, which attach
# their policy to a single role.
data "aws_iam_policy_document" "armonik" {
  statement {
    sid       = "ObjectStorageBucket"
    actions   = ["s3:ListBucket"]
    resources = [module.object_storage.arn]
  }

  statement {
    sid = "ObjectStorageObjects"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
      "s3:AbortMultipartUpload",
    ]
    resources = ["${module.object_storage.arn}/*"]
  }

  # S3 Express One Zone: a session per client, which then authorizes the object operations (ReadWrite by default)
  dynamic "statement" {
    for_each = module.object_storage_express
    content {
      sid       = "ObjectStorageExpress"
      actions   = ["s3express:CreateSession"]
      resources = [statement.value.arn]
    }
  }

  statement {
    sid = "Queues"
    actions = [
      "sqs:CreateQueue",
      "sqs:TagQueue",
      "sqs:GetQueueUrl",
      "sqs:GetQueueAttributes",
      "sqs:SendMessage",
      "sqs:ReceiveMessage",
      "sqs:DeleteMessage",
      "sqs:ChangeMessageVisibility",
    ]
    resources = ["arn:${local.partition}:sqs:${var.region}:${local.account_id}:${local.sqs_prefix}*"]
  }
}

resource "aws_iam_policy" "armonik" {
  name_prefix = "${local.name}-armonik-"
  description = "Object storage and queues of ArmoniK ${local.name}"
  policy      = data.aws_iam_policy_document.armonik.json
}

resource "aws_iam_role_policy_attachment" "armonik" {
  for_each = module.armonik_identity

  role       = each.value.service_account_iam_role_name
  policy_arn = aws_iam_policy.armonik.arn
}
