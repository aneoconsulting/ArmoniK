# Node IP of control plane pod
data "external" "control_plane_node_ip" {
  depends_on  = [kubernetes_service.control_plane]
  program     = ["bash", "get_node_ip.sh", "control-plane", var.namespace]
  working_dir = "../utils/scripts"
}

# Node IP
locals {
  control_plane_node_ip = lookup(tomap(data.external.control_plane_node_ip.result), "node_ip", "")
  control_plane_host    = (kubernetes_service.control_plane.spec.0.type == "LoadBalancer" ? kubernetes_service.control_plane.status.0.load_balancer.0.ingress.0.ip : (kubernetes_service.control_plane.spec.0.type == "NodePort" && local.control_plane_node_ip != "" ? local.control_plane_node_ip : kubernetes_service.control_plane.spec.0.cluster_ip))
  control_plane_port    = (kubernetes_service.control_plane.spec.0.type == "NodePort" && local.control_plane_node_ip != "" ? kubernetes_service.control_plane.spec.0.port.0.node_port : kubernetes_service.control_plane.spec.0.port.0.port)
  control_plane_url     = "http://${local.control_plane_host}:${local.control_plane_port}"
}

