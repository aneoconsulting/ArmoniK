# Node IP of control plane pod
data "external" "control_plane_node_ip" {
  depends_on  = [kubernetes_service.control_plane]
  program     = ["bash", "get_node_ip.sh", "control-plane", var.namespace]
  working_dir = "../utils/scripts"
}

# Node IP of Seq pod
data "external" "seq_node_ip" {
  depends_on  = [kubernetes_service.seq]
  program     = ["bash", "get_node_ip.sh", "seq", var.namespace]
  working_dir = "../utils/scripts"
}

# Node IP
locals {
  control_plane_node_ip = lookup(tomap(data.external.control_plane_node_ip.result), "node_ip", "")
  control_plane_host    = (local.control_plane_node_ip == "" ? kubernetes_service.control_plane.spec.cluster_ip : local.control_plane_node_ip)
  control_plane_port    = (local.control_plane_node_ip == "" ? kubernetes_service.control_plane.spec.0.port.0.port : kubernetes_service.control_plane.spec.0.port.0.node_port)
  control_plane_url     = "http://${local.control_plane_host}:${local.control_plane_port}"

  seq_node_ip = lookup(tomap(data.external.seq_node_ip.result), "node_ip", "")
  seq_host    = (local.seq_node_ip == "" ? kubernetes_service.seq.spec.cluster_ip : local.seq_node_ip)
  seq_port    = (local.seq_node_ip == "" ? kubernetes_service.seq.spec.0.port.0.port : kubernetes_service.seq.spec.0.port.0.node_port)
  seq_url     = "http://${local.seq_host}:${local.seq_port}"
}

