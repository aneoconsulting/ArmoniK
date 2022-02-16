# EKS
output "eks" {
  description = "EKS parameters"
  value       = {
    name                 = module.eks.eks_name
    cluster_id           = module.eks.cluster_id
    worker_iam_role_name = module.eks.worker_iam_role_name
  }
}