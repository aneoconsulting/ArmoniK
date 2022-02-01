output "s3_bucket_shared_storage" {
  description = "Amazon S3 bucket as shared storage"
  value       = {
    id        = module.s3fs_bucket.selected.s3_bucket_id
    host_path = var.s3fs_bucket.shared_host_path
    arn       = module.s3fs_bucket.selected.s3_bucket_arn
  }
}

output "vpc" {
  description = "Amazon VPC for EKS"
  value       = {
    name = module.vpc.selected.name
    id   = module.vpc.selected.vpc_id
    arn  = module.vpc.selected.vpc_arn
  }
}

output "eks" {
  description = "Amazon EKS"
  value       = {
    name    = module.eks.eks_cluster.cluster_id
    arn     = module.eks.eks_cluster.cluster_arn
    version = module.eks.eks_cluster.cluster_version
  }
}

output "kms" {
  description = "Amazon KMS"
  value       = {
    id  = module.kms.selected.key_id
    arn = module.kms.selected.arn
  }
}