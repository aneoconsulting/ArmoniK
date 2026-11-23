# Configuration of the ArmoniK CLI (make cliconfig)
resource "local_file" "armonik_cli_config" {
  content         = "# ArmoniK Connection Configuration\n---\n${yamlencode({ endpoint = try(module.armonik.endpoints.grpc, "") })}"
  filename        = "${path.root}/generated/armonik-cli.yaml"
  file_permission = "0644"
}

output "armonik" {
  description = "ArmoniK endpoint URL"
  value = {
    control_plane_url = try(module.armonik.endpoints.grpc, null)
    grafana_url       = try(module.armonik.endpoints.grafana, null)
    seq_web_url       = try(module.armonik.endpoints.seq, null)
    admin_app_url     = try(module.armonik.endpoints.gui, null)
    chaos_mesh_url    = one(module.chaos_mesh[*].chaos_mesh_url)
  }
}

output "grafana_admin_password" {
  description = "Password of the Grafana user admin (terraform output -raw grafana_admin_password)"
  value       = module.armonik.grafana_admin_password
  sensitive   = true
}

output "gke" {
  description = "GKE cluster"
  value = {
    arn             = module.gke.id
    name            = module.gke.name
    region          = module.gke.region
    kubeconfig_file = abspath(var.gke.kubeconfig_file)
  }
}

output "gcs_fs_name" {
  description = "Name of GCS bucket for application DLLs."
  value       = module.gcs_fs.name
}

output "kubeconfig" {
  description = "Use multiple Kubernetes cluster with KUBECONFIG environment variable"
  value       = "export KUBECONFIG=${abspath(var.gke.kubeconfig_file)}"
}
