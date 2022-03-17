# Node IP of control plane pod
data "external" "control_plane_node_ip" {
  depends_on  = [kubernetes_service.control_plane]
  program     = ["bash", "get_node_ip.sh", "control-plane", var.namespace]
  working_dir = "${var.working_dir}/utils/scripts"
}

locals {
  control_plane_node_ip = try(tomap(data.external.control_plane_node_ip.result).node_ip, "")

  load_balancer = (kubernetes_service.control_plane.spec.0.type == "LoadBalancer" ? {
    ip   = (kubernetes_service.control_plane.status.0.load_balancer.0.ingress.0.ip == "" ? kubernetes_service.control_plane.status.0.load_balancer.0.ingress.0.hostname : kubernetes_service.control_plane.status.0.load_balancer.0.ingress.0.ip)
    port = kubernetes_service.control_plane.spec.0.port.0.port
  } : {
    ip   = ""
    port = ""
  })

  node_port = (local.load_balancer.ip == "" && kubernetes_service.control_plane.spec.0.type == "NodePort" ? {
    ip   = local.control_plane_node_ip
    port = kubernetes_service.control_plane.spec.0.port.0.node_port
  } : {
    ip   = local.load_balancer.ip
    port = local.load_balancer.port
  })

  control_plane_endpoints = (local.node_port.ip == "" && kubernetes_service.control_plane.spec.0.type == "ClusterIP" ? {
    ip   = kubernetes_service.control_plane.spec.0.cluster_ip
    port = kubernetes_service.control_plane.spec.0.port.0.port
  } : {
    ip   = local.node_port.ip
    port = local.node_port.port
  })

  control_plane_url = "http://${local.control_plane_endpoints.ip}:${local.control_plane_endpoints.port}"
}