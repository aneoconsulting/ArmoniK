output "selected" {
  description = "Created VPC"
  value       = module.vpc
}

output "id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "cidr_block" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_cidr_block
}

output "private_subnet_ids" {
  description = "ids of the private subnet created"
  value       = matchkeys(module.vpc.private_subnets, tolist(module.vpc.private_subnets_cidr_blocks), var.vpc.private_subnets)
}

output "public_subnet_ids" {
  description = "ids of the public subnet created"
  value       = matchkeys(module.vpc.public_subnets, tolist(module.vpc.public_subnets_cidr_blocks), var.vpc.public_subnets)
}

output "pods_subnet_ids" {
  description = "ids of the private subnet created"
  value       = matchkeys(module.vpc.private_subnets, tolist(module.vpc.private_subnets_cidr_blocks), var.vpc.pod_cidr_block_private)
}

output "pod_cidr_block_private" {
  description = "CIDR Pod private subnets"
  value       = var.vpc.pod_cidr_block_private
}

output "kms_key_id" {
  description = "ARN of KMS used for VPC"
  value       = var.vpc.flow_log_cloudwatch_log_group_kms_key_id
}



