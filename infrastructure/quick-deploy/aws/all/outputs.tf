output "armonik" {
  description = "ArmoniK endpoint URL"
  value = {
    control_plane_url = module.armonik.endpoint_urls.control_plane_url
    grafana_url       = module.armonik.endpoint_urls.grafana_url
    seq_web_url       = module.armonik.endpoint_urls.seq_web_url
    admin_api_url     = module.armonik.endpoint_urls.admin_api_url
    admin_app_url     = module.armonik.endpoint_urls.admin_app_url
    admin_old_url     = module.armonik.endpoint_urls.admin_old_url
  }
}

output "eks" {
  description = "EKS cluster"
  value = {
    arn             = module.eks.arn
    name            = module.eks.cluster_name
    region          = var.region
    kubeconfig_file = module.eks.kubeconfig_file
  }
}

output "s3_fs_name" {
  description = "Name of S3 bucket for application DLLs."
  value       = module.s3_fs.s3_bucket_name
}
