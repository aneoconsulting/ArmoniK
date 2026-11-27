output "kubeconfig_command" {
  description = "Command writing the kubeconfig of the cluster, with the context named after the prefix"
  value       = "aws eks update-kubeconfig --region ${var.region} --name ${module.eks.cluster_name} --alias ${local.name}"
}

output "endpoints" {
  description = "URLs of ArmoniK (gRPC, GUI, Grafana, Seq), null until the NLB has an address"
  value       = module.armonik.endpoints
}

output "grafana_admin_password" {
  description = "Password of the Grafana user admin"
  value       = module.armonik.grafana_admin_password
  sensitive   = true
}

output "workers_repository" {
  description = "ECR repository of the worker images, to push to and to use as partitions.<name>.image"
  value       = aws_ecr_repository.workers.repository_url
}

output "node_role_arns" {
  description = "Node roles pulling the images: grant them pull access on a worker repository of another account"
  value = {
    system    = module.eks.eks_managed_node_groups["system"].iam_role_arn
    karpenter = module.karpenter.node_iam_role_arn
  }
}

output "database" {
  description = "Aurora cluster: the writer endpoint (GetEvents), the RDS Proxy endpoint (the rest), the credentials secret"
  value = {
    cluster_identifier = module.database.cluster_identifier
    host               = module.database.host
    pooler_host        = module.database.pooler_host
    secret_name        = module.database.secret_name
  }
}

output "registries" {
  description = "ECR pull-through cache of each upstream registry (dockerHub, ghcr, quay, k8s, ecrPublic): <registry>/<image path>"
  value       = local.registries
}
