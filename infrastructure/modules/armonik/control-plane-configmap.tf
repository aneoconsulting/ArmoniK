# configmap with all the variables
resource "kubernetes_config_map" "control_plane_config" {
  metadata {
    name      = "control-plane-configmap"
    namespace = var.namespace
  }
  data = {
    Submitter__DefaultPartition = (local.default_partition == null || local.default_partition == "" || !contains(local.partition_names, local.default_partition) ? (length(local.partition_names) > 0 ? local.partition_names[0] : "") : local.default_partition)
  }
}
