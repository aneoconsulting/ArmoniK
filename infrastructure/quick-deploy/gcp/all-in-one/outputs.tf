output "gke" {
  description = "GKE cluster"
  value       = {
    arn             = module.gke.cluster_id
    name            = module.gke.name
    region          = var.region
    kubeconfig_file = abspath(var.kubeconfig_file)
  }
}

