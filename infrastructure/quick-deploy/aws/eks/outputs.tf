# EKS
output "eks" {
  description = "EKS parameters"
  value = {
    cluster_name                       = module.eks.cluster_name
    cluster_id                         = module.eks.cluster_id
    self_managed_worker_iam_role_names = module.eks.self_managed_worker_iam_role_names
    issuer                             = module.eks.issuer
    kubeconfig_file                    = module.eks.kubeconfig_file
  }
}


output "kubeconfig" {
  description = "Use multiple Kubernetes cluster with KUBECONFIG environment variable"
  value       = "export KUBECONFIG=${module.eks.kubeconfig_file} && kubectl config use-context ${module.eks.cluster_name}"
}
