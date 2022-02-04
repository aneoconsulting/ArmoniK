output "repositories" {
  description = "List of ECR repositories"
  value       = [for repo in aws_ecr_repository.ecr : repo.repository_url]
}

output "kms_key_id" {
  description = "ARN of KMS used for ECR"
  value       = var.kms_key_id
}