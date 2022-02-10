# EKS
output "eks" {
  description = "EKS parameters"
  value       = {
    name = module.eks.eks_name
  }
}