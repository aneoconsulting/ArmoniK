# VPC
output "vpc" {
  description = "VPC infos"
  value       = {
    id          = module.vpc.id
    cidr_blocks = concat([module.vpc.cidr_block], module.vpc.pod_cidr_block_private)
    subnet_ids  = module.vpc.private_subnet_ids
  }
}