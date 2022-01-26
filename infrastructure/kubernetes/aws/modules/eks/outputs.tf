output "eks_cluster" {
  description = "EKS object"
  value       = module.eks
}

output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = module.eks.cluster_endpoint
}

output "certificate_authority" {
  description = "Endpoint for EKS control plane"
  value       = data.aws_eks_cluster.cluster.certificate_authority
}

output "token" {
  description = "Authentication token for EKS"
  value       = data.aws_eks_cluster_auth.cluster.token
  sensitive   = true
}
