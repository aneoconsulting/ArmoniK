# GKE
output "gke" {
  description = "GKE parameters"
  value = {
    endpoint        = module.gke.endpoint
    ca_certificate  = module.gke.ca_certificate
    cluster_name    = module.gke.name
    cluster_id      = module.gke.cluster_id
    kubeconfig_path = module.gke.kubeconfig_path
    service_account = module.gke.service_account
  }
  sensitive = true
}

output "kubeconfig" {
  description = "Use multiple Kubernetes cluster with KUBECONFIG environment variable"
  value       = "export KUBECONFIG=${module.gke.kubeconfig_path}"
}
