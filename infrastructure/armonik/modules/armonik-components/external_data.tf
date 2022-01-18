# Node IP of control plane pod
data "external" "control_plane_node_ip" {
  depends_on  = [kubernetes_service.control_plane]
  program     = ["bash", "get_node_ip.sh", "control-plane", var.namespace]
  working_dir = "../utils/scripts"
}

# Node IP
locals {
  control_plane_node_ip = lookup(tomap(data.external.control_plane_node_ip.result), "node_ip", "")
  control_plane_host    = (local.control_plane_node_ip == "" ? kubernetes_service.control_plane.spec.0.cluster_ip : local.control_plane_node_ip)
  control_plane_port    = (local.control_plane_node_ip == "" ? kubernetes_service.control_plane.spec.0.port.0.port : kubernetes_service.control_plane.spec.0.port.0.node_port)
  control_plane_url     = "http://${local.control_plane_host}:${local.control_plane_port}"
}

