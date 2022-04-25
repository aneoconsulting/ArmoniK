# Node IP of control plane pod
data "external" "control_plane_node_ip" {
  depends_on  = [kubernetes_service.control_plane]
  program     = ["bash", "get_node_ip.sh", "control-plane", var.namespace]
  working_dir = "${var.working_dir}/utils/scripts"
}

locals {
  control_plane_node_ip = try(tomap(data.external.control_plane_node_ip.result).node_ip, "")

  control_plane_load_balancer = (kubernetes_service.control_plane.spec.0.type == "LoadBalancer" ? {
    ip   = (kubernetes_service.control_plane.status.0.load_balancer.0.ingress.0.ip == "" ? kubernetes_service.control_plane.status.0.load_balancer.0.ingress.0.hostname : kubernetes_service.control_plane.status.0.load_balancer.0.ingress.0.ip)
    port = kubernetes_service.control_plane.spec.0.port.0.port
  } : {
    ip   = ""
    port = ""
  })

  control_plane_node_port = (local.control_plane_load_balancer.ip == "" && kubernetes_service.control_plane.spec.0.type == "NodePort" ? {
    ip   = local.control_plane_node_ip
    port = kubernetes_service.control_plane.spec.0.port.0.node_port
  } : {
    ip   = local.control_plane_load_balancer.ip
    port = local.control_plane_load_balancer.port
  })

  control_plane_endpoints = (local.control_plane_node_port.ip == "" && kubernetes_service.control_plane.spec.0.type == "ClusterIP" ? {
    ip   = kubernetes_service.control_plane.spec.0.cluster_ip
    port = kubernetes_service.control_plane.spec.0.port.0.port
  } : {
    ip   = local.control_plane_node_port.ip
    port = local.control_plane_node_port.port
  })

  control_plane_url = "http://${local.control_plane_endpoints.ip}:${local.control_plane_endpoints.port}"
}

# Node IP of admin GUI pod
data "external" "admin_gui_node_ip" {
  depends_on  = [kubernetes_service.admin_gui]
  program     = ["bash", "get_node_ip.sh", "admin-gui", var.namespace]
  working_dir = "${var.working_dir}/utils/scripts"
}

locals {  
  admin_gui_node_ip = try(tomap(data.external.admin_gui_node_ip.result).node_ip, "")

  admin_gui_load_balancer = (kubernetes_service.admin_gui.spec.0.type == "LoadBalancer" ? {
    ip       = (kubernetes_service.admin_gui.status.0.load_balancer.0.ingress.0.ip == "" ? kubernetes_service.admin_gui.status.0.load_balancer.0.ingress.0.hostname : kubernetes_service.admin_gui.status.0.load_balancer.0.ingress.0.ip)
    api_port = kubernetes_service.admin_gui.spec.0.port.0.port
    app_port = kubernetes_service.admin_gui.spec.0.port.1.port
  } : {
    ip       = ""
    api_port = ""
    app_port = ""
  })

  admin_gui_node_port = (local.admin_gui_load_balancer.ip == "" && kubernetes_service.admin_gui.spec.0.type == "NodePort" ? {
    ip       = local.admin_gui_node_ip
    api_port = kubernetes_service.admin_gui.spec.0.port.0.node_port
    app_port = kubernetes_service.admin_gui.spec.0.port.1.node_port
  } : {
    ip       = local.admin_gui_load_balancer.ip
    api_port = local.admin_gui_load_balancer.api_port
    app_port = local.admin_gui_load_balancer.app_port
  })

  admin_gui_endpoints = (local.admin_gui_node_port.ip == "" && kubernetes_service.admin_gui.spec.0.type == "ClusterIP" ? {
    ip       = kubernetes_service.admin_gui.spec.0.cluster_ip
    api_port = kubernetes_service.admin_gui.spec.0.port.0.port
    app_port = kubernetes_service.admin_gui.spec.0.port.1.port
  } : {
    ip       = local.admin_gui_node_port.ip
    api_port = local.admin_gui_node_port.api_port
    app_port = local.admin_gui_node_port.app_port
  })

  admin_api_url = "http://${local.admin_gui_endpoints.ip}:${local.admin_gui_endpoints.api_port}"
  admin_app_url = "http://${local.admin_gui_endpoints.ip}:${local.admin_gui_endpoints.app_port}"
}
