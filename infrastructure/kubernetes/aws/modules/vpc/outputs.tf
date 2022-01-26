output "selected" {
  description = "Created VPC"
  value       = module.vpc
}

output "private_subnet_ids" {
  description = "ids of the private subnet created"
  value       = matchkeys(module.vpc.private_subnets, tolist(module.vpc.private_subnets_cidr_blocks), var.vpc.private_subnets)
}

output "pods_subnet_ids" {
  description = "ids of the private subnet created"
  value       = matchkeys(module.vpc.private_subnets, tolist(module.vpc.private_subnets_cidr_blocks), var.vpc.pod_cidr_block_private)
}