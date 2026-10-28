output "prefix" {
  description = "Name prefix of every resource"
  value       = local.name
}

output "kubeconfig_command" {
  description = "Command writing the kubeconfig of the cluster, with the context named after the prefix"
  value       = "aws eks update-kubeconfig --region ${var.region} --name ${module.eks.cluster_name} --alias ${local.name}"
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

# Everything terraform/k8s needs, read there through terraform_remote_state
output "k8s" {
  description = "Inputs of terraform/k8s"
  value = {
    region       = var.region
    cluster_name = module.eks.cluster_name
    endpoint     = module.eks.cluster_endpoint
    ca_data      = module.eks.cluster_certificate_authority_data
    vpc_id       = module.vpc.vpc_id
    registry     = local.registry
    registries   = local.registries
    namespaces = {
      armonik   = var.namespace
      operators = var.operators_namespace
    }
    service_accounts = local.service_accounts
    karpenter = {
      node_role     = module.karpenter.node_iam_role_name
      queue_name    = module.karpenter.queue_name
      discovery_tag = local.name
    }
    postgresql = {
      host          = module.rds.db_instance_address
      port          = module.rds.db_instance_port
      database      = "armonik"
      secret_arn    = module.rds.db_instance_master_user_secret_arn
      ca_secret_arn = aws_secretsmanager_secret.rds_ca.arn
    }
    sqs_prefix = local.sqs_prefix
    s3_bucket  = module.object_storage.s3_bucket_id
  }
}
