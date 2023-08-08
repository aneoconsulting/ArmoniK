# VPC
output "vpc" {
  description = "VPC infos"
  value = {
    id                     = module.vpc.id
    cidr_block             = module.vpc.cidr_block
    cidr_block_private     = module.vpc.private_subnets_cidr_blocks
    private_subnet_ids     = module.vpc.private_subnets
    public_subnet_ids      = module.vpc.public_subnets
    pods_subnet_ids        = module.vpc.pod_subnets
    pod_cidr_block_private = module.vpc.pod_subnets_cidr_blocks
    eks_cluster_name       = local.cluster_name
  }
}
