# EKS Pod Identity roles, bound to namespace/service account pairs

# Control plane and compute plane (polling agent): object storage and queues, exactly the calls the
# Core S3 and SQS adaptors make
data "aws_iam_policy_document" "armonik" {
  statement {
    sid       = "ObjectStorageBucket"
    actions   = ["s3:ListBucket"]
    resources = [module.object_storage.s3_bucket_arn]
  }

  statement {
    sid = "ObjectStorageObjects"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
      "s3:AbortMultipartUpload",
    ]
    resources = ["${module.object_storage.s3_bucket_arn}/*"]
  }

  statement {
    sid       = "ObjectStorageKey"
    actions   = ["kms:GenerateDataKey", "kms:Decrypt"]
    resources = [module.kms.key_arn]
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

module "armonik_identity" {
  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "~> 2.9"

  name            = "${local.name}-armonik"
  use_name_prefix = false

  attach_custom_policy    = true
  source_policy_documents = [data.aws_iam_policy_document.armonik.json]

  associations = {
    for component, service_account in local.service_accounts : component => {
      cluster_name    = module.eks.cluster_name
      namespace       = var.namespace
      service_account = service_account
    }
  }
}

# External Secrets Operator: reads the RDS master user secret for the ArmoniK conf layers
module "external_secrets_identity" {
  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "~> 2.9"

  name            = "${local.name}-external-secrets"
  use_name_prefix = false

  attach_external_secrets_policy        = true
  external_secrets_secrets_manager_arns = [module.rds.db_instance_master_user_secret_arn]
  external_secrets_create_permission    = false

  associations = {
    operator = {
      cluster_name    = module.eks.cluster_name
      namespace       = var.operators_namespace
      service_account = "external-secrets"
    }
  }
}

module "aws_load_balancer_controller_identity" {
  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "~> 2.9"

  name            = "${local.name}-aws-lb-controller"
  use_name_prefix = false

  attach_aws_lb_controller_policy = true

  associations = {
    controller = {
      cluster_name    = module.eks.cluster_name
      namespace       = "kube-system"
      service_account = "aws-load-balancer-controller"
    }
  }
}

# The association is made by the EKS addon itself
module "ebs_csi_identity" {
  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "~> 2.9"

  name            = "${local.name}-ebs-csi"
  use_name_prefix = false

  attach_aws_ebs_csi_policy = true
}
