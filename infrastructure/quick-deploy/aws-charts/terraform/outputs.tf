# make output writes these values, unwrapped, to generated/armonik-output.json: the helmfile reads
# them as its environment values, and ArmoniK.Action.Deploy reads eks.name and eks.region.

output "eks" {
  description = "EKS cluster"
  value = {
    name     = module.eks.cluster_name
    region   = var.region
    endpoint = module.eks.cluster_endpoint
    vpc_id   = module.vpc.vpc_id
  }
}

output "namespaces" {
  description = "Namespaces the Pod Identity associations are bound to"
  value = {
    armonik   = var.namespace
    operators = var.operators_namespace
  }
}

output "service_accounts" {
  description = "Service accounts the ArmoniK charts must use"
  value       = local.service_accounts
}

output "registry" {
  description = "ECR registry, and the pull-through cache prefix of each upstream"
  value = {
    host      = local.registry
    upstreams = local.registries
  }
}

output "karpenter" {
  description = "Karpenter settings"
  value = {
    node_role      = module.karpenter.node_iam_role_name
    queue_name     = module.karpenter.queue_name
    discovery_tag  = local.name
    cluster_name   = module.eks.cluster_name
    cluster_region = var.region
  }
}

output "postgresql" {
  description = "RDS PostgreSQL endpoint, and the Secrets Manager secret holding its master user"
  value = {
    host       = module.rds.db_instance_address
    port       = module.rds.db_instance_port
    database   = "armonik"
    secret_arn = module.rds.db_instance_master_user_secret_arn
  }
}

output "object_storage" {
  description = "S3 bucket of the object storage"
  value = {
    bucket = module.object_storage.s3_bucket_id
  }
}

output "queue" {
  description = "SQS settings"
  value = {
    prefix = local.sqs_prefix
  }
}

output "kubeconfig_command" {
  description = "Command writing the kubeconfig of the cluster"
  value       = "aws eks update-kubeconfig --region ${var.region} --name ${module.eks.cluster_name}"
}
