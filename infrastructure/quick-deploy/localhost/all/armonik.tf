module "armonik" {
  source               = "../../../modules/armonik"
  working_dir          = "${path.root}/../../.."
  namespace            = local.namespace
  logging_level        = var.logging_level
  storage_endpoint_url = local.storage_endpoint_url
  monitoring           = local.monitoring
  extra_conf           = var.extra_conf
  // If compute plane has no partition data, provides a default
  // but always overrides the images
  compute_plane = {
    for k, v in var.compute_plane : k => merge({
      partition_data = {
        priority              = 1
        reserved_pods         = 1
        max_pods              = 100
        preemption_percentage = 50
        parent_partition_ids  = []
        pod_configuration     = null
      }
    }, v)
  }
  control_plane              = var.control_plane
  admin_gui                  = var.admin_gui
  ingress                    = var.ingress
  job_partitions_in_database = var.job_partitions_in_database
  authentication             = var.authentication
  depends_on = [
    kubernetes_secret.fluent_bit,
    kubernetes_secret.grafana,
    kubernetes_secret.metrics_exporter,
    kubernetes_secret.partition_metrics_exporter,
    kubernetes_secret.seq,
    kubernetes_secret.shared_storage
  ]
}
