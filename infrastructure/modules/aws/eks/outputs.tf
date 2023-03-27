output "arn" {
  description = "ARN of EKS cluster"
  value       = module.eks.cluster_arn
}

output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = module.eks.cluster_endpoint
}

output "aws_eks_module" {
  description = "aws eks module"
  value       = module.eks
}

output "cluster_certificate_authority_data" {
  description = "cluster_certificate_authority_data"
  value       = module.eks.cluster_certificate_authority_data
}

output "cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "cluster_id" {
  description = "EKS cluster ID  used for backword compatibility : https://github.com/terraform-aws-modules/terraform-aws-eks/blob/master/docs/UPGRADE-19.0.md#list-of-backwards-incompatible-changes"
  value       = module.eks.cluster_name
}


output "kms_key_id" {
  description = "ARN of KMS used for EKS"
  value = {
    cluster_log_kms_key_id    = var.eks.encryption_keys.cluster_log_kms_key_id
    cluster_encryption_config = var.eks.encryption_keys.cluster_encryption_config
    ebs_kms_key_id            = var.eks.encryption_keys.ebs_kms_key_id
  }
}


output "worker_iam_role_name" {
  description = "EKS worker IAM role name"
  #value       = module.eks.self_managed_node_groups["worker-c5.4xlarge-spot"].iam_role_name
  #value =       try(values(module.eks.self_managed_node_groups).1.iam_role_name, "")
  value = module.eks.cluster_iam_role_name
}

output "self_managed_worker_iam_role_names"{
  description = "list of the self managed workers IAM role names"
  value = values(module.eks.self_managed_node_groups)[*].iam_role_name
}

output "cluster_iam_role_name"{
  description = "Cluster IAM role name"
  value = module.eks.cluster_iam_role_name
}

output "eks_managed_node_groups" {
  description = "List of EKS managed group nodes"
  value = module.eks.eks_managed_node_groups
}

output "self_managed_node_groups" {
  description = "List of self managed node groups"
  value = module.eks.self_managed_node_groups
}

output "fargate_profiles" {
  description = "List of fargate profiles"
  value = module.eks.fargate_profiles
}

output "issuer" {
  description = "EKS Identity issuer"
  value       = module.eks.cluster_oidc_issuer_url
}