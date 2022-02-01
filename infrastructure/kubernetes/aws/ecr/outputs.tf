output "ecr_repositories" {
  description = "List of created ECR repositories"
  value       = [for repo in aws_ecr_repository.ecr : repo.repository_url]
}