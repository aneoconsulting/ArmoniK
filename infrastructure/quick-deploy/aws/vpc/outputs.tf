# VPC
output "vpc" {
  description = "VPC infos"
  value       = {
    id                     = module.vpc.id
    cidr_block             = module.vpc.cidr_block
    private_subnet_ids     = module.vpc.private_subnet_ids
    pod_cidr_block_private = module.vpc.pod_cidr_block_private
    pods_subnet_ids        = module.vpc.pods_subnet_ids
  }
}