output "armonik" {
  description = "ArmoniK endpoint URL"
  value = {
    control_plane_url = module.armonik.endpoint_urls.control_plane_url
    grafana_url       = module.armonik.endpoint_urls.grafana_url
    seq_web_url       = module.armonik.endpoint_urls.seq_web_url
    admin_app_url     = module.armonik.endpoint_urls.admin_app_url
    chaos_mesh_url    = one(module.chaos_mesh[*].chaos_mesh_url)
  }
}

output "gke" {
  description = "GKE cluster"
  value = {
    arn    = module.gke.cluster_id
    name   = module.gke.name
    region = module.gke.region
    #kubeconfig_file = module.gke.kubeconfig_file
    kubeconfig_file = abspath(var.gke.kubeconfig_file)
  }
}

output "gcs_fs_name" {
  description = "Name of GCS bucket for application DLLs."
  value       = module.gcs_fs.name
}

output "kubeconfig" {
  description = "Use multiple Kubernetes cluster with KUBECONFIG environment variable"
  #value       = "export KUBECONFIG=${module.gke.kubeconfig_file}"
  value = "export KUBECONFIG=${abspath(var.gke.kubeconfig_file)}"
}


