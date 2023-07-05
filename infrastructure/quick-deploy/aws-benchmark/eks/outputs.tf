# EKS
output "eks" {
  description = "EKS parameters"
  value = {
    cluster_name                           = module.eks.cluster_name
    cluster_id                             = module.eks.cluster_id
    eks_managed_worker_iam_role_names      = module.eks.eks_managed_worker_iam_role_names
    self_managed_worker_iam_role_names     = module.eks.self_managed_worker_iam_role_names
    fargate_profiles_worker_iam_role_names = module.eks.fargate_profiles_worker_iam_role_names
    worker_iam_role_names                  = module.eks.worker_iam_role_names
    issuer                                 = module.eks.issuer
    kubeconfig_file                        = module.eks.kubeconfig_file
  }
}

output "kubeconfig" {
  description = "Use multiple Kubernetes cluster with KUBECONFIG environment variable"
  value       = "export KUBECONFIG=${module.eks.kubeconfig_file}"
}
