# configmap with all the variables
resource "kubernetes_config_map" "control_plane_config" {
  metadata {
    name      = "control-plane-configmap"
    namespace = var.namespace
  }
  data = {
    ControlPlane__Partitions       = join(",", local.partition_names)
    ControlPlane__DefaultPartition = (local.default_partition == null ? "" : local.default_partition)
  }
}
