# VPC
output "vpc" {
  description = "VPC infos"
  value = {
    id                     = module.vpc.id
    cidr_block             = module.vpc.cidr_block
    cidr_block_private     = var.vpc.cidr_block_private
    private_subnet_ids     = module.vpc.private_subnet_ids
    public_subnet_ids      = module.vpc.public_subnet_ids
    pods_subnet_ids        = module.vpc.pods_subnet_ids
    pod_cidr_block_private = module.vpc.pod_cidr_block_private
    eks_cluster_name       = local.cluster_name
  }
}
