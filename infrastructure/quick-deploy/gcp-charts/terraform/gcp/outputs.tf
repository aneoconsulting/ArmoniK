# env, not a bare KUBECONFIG=: the command runs through $(...), where a leading assignment is not recognized
output "kubeconfig_command" {
  description = "Command writing the kubeconfig of the cluster, through its DNS endpoint, to ./kubeconfig: run it from gcp-charts/"
  value       = "env KUBECONFIG=kubeconfig gcloud container clusters get-credentials ${module.gke.name} --dns-endpoint --location ${module.gke.location} --project ${var.project}"
}

output "object_storage_bucket" {
  description = "Bucket of the object storage of Core"
  value       = module.object_storage.name
}

# Everything terraform/k8s needs, read there through terraform_remote_state
output "k8s" {
  description = "Inputs of terraform/k8s"
  value = {
    project          = var.project
    endpoint_dns     = module.gke.endpoint_dns
    namespaces       = local.namespaces
    service_accounts = local.service_accounts
    workers          = local.workers
    bucket           = module.object_storage.name
    pubsub_prefix    = var.prefix
  }
}
