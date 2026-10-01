# Karpenter controller role (Pod Identity, kube-system/karpenter), node role and access entry, and the
# SQS queue fed by EventBridge with the spot interruptions and rebalance recommendations. The
# controller itself, the EC2NodeClass and the NodePools are deployed by the helmfile.
module "karpenter" {
  source  = "terraform-aws-modules/eks/aws//modules/karpenter"
  version = "~> 21.26"

  cluster_name = module.eks.cluster_name

  # The controller policy exceeds the 6144 characters of a managed policy; inline allows 10240
  enable_inline_policy = true

  # Named, since the EC2NodeClass references it
  node_iam_role_use_name_prefix     = false
  node_iam_role_name                = "${local.name}-karpenter-node"
  node_iam_role_additional_policies = local.node_iam_policies
}
