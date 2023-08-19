output "gke" {
  description = "GKE cluster"
  value = {
    arn             = module.gke.cluster_id
    name            = module.gke.name
    region          = module.gke.region
    kubeconfig_file = abspath(var.gke.kubeconfig_file)
  }
}

