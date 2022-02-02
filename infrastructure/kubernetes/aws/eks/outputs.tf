output "s3_bucket_shared_storage" {
  description = "Amazon S3 bucket as shared storage"
  value       = {
    id        = module.s3fs_bucket.selected.s3_bucket_id
    host_path = var.s3fs_bucket.shared_host_path
  }
}

output "vpc" {
  description = "Amazon VPC for EKS"
  value       = {
    id                     = module.vpc.id
    cidr_block             = module.vpc.cidr_block
    pod_cidr_block_private = module.vpc.pod_cidr_block_private
    private_subnet_ids     = module.vpc.private_subnet_ids
  }
}

output "eks" {
  description = "Amazon EKS"
  value       = {
    name    = module.eks.eks_cluster.cluster_id
    version = module.eks.eks_cluster.cluster_version
  }
}