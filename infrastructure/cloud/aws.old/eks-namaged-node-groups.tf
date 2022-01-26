module "armonik_managed_node_group" {
  source          = "terraform-aws-modules/eks/aws//modules/eks-managed-node-group"
  version         = "18.2.2"
  name            = var.armonik_managed_node_group.name
  cluster_name    = module.eks.armonik.cluster_id
  cluster_version = var.eks_parameters.version
  vpc_id          = module.vpc.armonik.vpc_id
  subnet_ids      = module.vpc.armonik.private_subnets
  tags            = merge(local.tags, { resource = "EKS managed node group" })
}