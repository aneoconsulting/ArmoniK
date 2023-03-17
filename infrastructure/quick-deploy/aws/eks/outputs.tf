# EKS
output "eks" {
  description = "EKS parameters"
  value = {
    name                    = module.eks.name
    cluster_id              = module.eks.cluster_id
    worker_iam_role_name    = module.eks.worker_iam_role_name
    issuer                  = module.eks.issuer
  }
}