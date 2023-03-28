# EKS
output "eks" {
  description = "EKS parameters"
  value = {
    name                 = module.eks.cluster_name
    cluster_id           = module.eks.cluster_id
    worker_iam_role_name = module.eks.worker_iam_role_name
    self_managed_worker_iam_role_names = module.eks.self_managed_worker_iam_role_names
    issuer               = module.eks.issuer
  }
}