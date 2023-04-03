# EKS
output "eks" {
  description = "EKS parameters"
  value = {
    cluster_name                       = module.eks.cluster_name
    cluster_id                         = module.eks.cluster_id
    self_managed_worker_iam_role_names = module.eks.self_managed_worker_iam_role_names
    issuer                             = module.eks.issuer
  }
}