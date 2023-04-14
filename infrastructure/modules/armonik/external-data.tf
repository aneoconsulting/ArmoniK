locals {
  control_plane_load_balancer = (kubernetes_service.control_plane.spec.0.type == "LoadBalancer" ? {
    ip   = (kubernetes_service.control_plane.status.0.load_balancer.0.ingress.0.ip == "" ? kubernetes_service.control_plane.status.0.load_balancer.0.ingress.0.hostname : kubernetes_service.control_plane.status.0.load_balancer.0.ingress.0.ip)
    port = kubernetes_service.control_plane.spec.0.port.0.port
    } : {
    ip   = ""
    port = ""
  })

  control_plane_endpoints = (local.control_plane_load_balancer.ip == "" && kubernetes_service.control_plane.spec.0.type == "ClusterIP" ? {
    ip   = kubernetes_service.control_plane.spec.0.cluster_ip
    port = kubernetes_service.control_plane.spec.0.port.0.port
    } : {
    ip   = local.control_plane_load_balancer.ip
    port = local.control_plane_load_balancer.port
  })

  admin_gui_load_balancer = length(kubernetes_service.admin_gui) > 0 ? (kubernetes_service.admin_gui[0].spec.0.type == "LoadBalancer" ? {
    ip       = (kubernetes_service.admin_gui[0].status.0.load_balancer.0.ingress.0.ip == "" ? kubernetes_service.admin_gui[0].status.0.load_balancer.0.ingress.0.hostname : kubernetes_service.admin_gui[0].status.0.load_balancer.0.ingress.0.ip)
    app_port = kubernetes_service.admin_gui[0].spec.0.port.0.port
    } : {
    ip       = ""
    app_port = ""
  }) : null

  admin_gui_endpoints = length(kubernetes_service.admin_gui) > 0 ? (local.admin_gui_load_balancer.ip == "" && kubernetes_service.admin_gui[0].spec.0.type == "ClusterIP" ? {
    ip       = kubernetes_service.admin_gui[0].spec.0.cluster_ip
    app_port = kubernetes_service.admin_gui[0].spec.0.port.0.port
    } : {
    ip       = local.admin_gui_load_balancer.ip
    app_port = local.admin_gui_load_balancer.app_port
  }) : null

  admin_old_gui_load_balancer = length(kubernetes_service.admin_old_gui) > 0 ? (kubernetes_service.admin_old_gui[0].spec.0.type == "LoadBalancer" ? {
    ip       = (kubernetes_service.admin_old_gui[0].status.0.load_balancer.0.ingress.0.ip == "" ? kubernetes_service.admin_old_gui[0].status.0.load_balancer.0.ingress.0.hostname : kubernetes_service.admin_old_gui[0].status.0.load_balancer.0.ingress.0.ip)
    api_port = kubernetes_service.admin_old_gui[0].spec.0.port.0.port
    app_port = kubernetes_service.admin_old_gui[0].spec.0.port.1.port
    } : {
    ip       = ""
    api_port = ""
    app_port = ""
  }) : null

  admin_old_gui_endpoints = length(kubernetes_service.admin_old_gui) > 0 ? (local.admin_old_gui_load_balancer.ip == "" && kubernetes_service.admin_old_gui[0].spec.0.type == "ClusterIP" ? {
    ip       = kubernetes_service.admin_old_gui[0].spec.0.cluster_ip
    api_port = kubernetes_service.admin_old_gui[0].spec.0.port.0.port
    app_port = kubernetes_service.admin_old_gui[0].spec.0.port.1.port
    } : {
    ip       = local.admin_old_gui_load_balancer.ip
    api_port = local.admin_old_gui_load_balancer.api_port
    app_port = local.admin_old_gui_load_balancer.app_port
  }) : null

  ingress_load_balancer = (var.ingress != null ? kubernetes_service.ingress.0.spec.0.type == "LoadBalancer" : false) ? {
    ip        = (kubernetes_service.ingress.0.status.0.load_balancer.0.ingress.0.ip == "" ? kubernetes_service.ingress.0.status.0.load_balancer.0.ingress.0.hostname : kubernetes_service.ingress.0.status.0.load_balancer.0.ingress.0.ip)
    http_port = var.ingress.http_port
    grpc_port = var.ingress.grpc_port
    } : {
    ip        = ""
    http_port = ""
    grpc_port = ""
  }

  ingress_endpoint = (var.ingress != null ? local.ingress_load_balancer.ip == "" && kubernetes_service.ingress.0.spec.0.type == "ClusterIP" : false) ? {
    ip        = kubernetes_service.ingress.0.spec.0.cluster_ip
    http_port = var.ingress.http_port
    grpc_port = var.ingress.grpc_port
    } : {
    ip        = local.ingress_load_balancer.ip
    http_port = local.ingress_load_balancer.http_port
    grpc_port = local.ingress_load_balancer.grpc_port
  }

  control_plane_url = "http://${local.control_plane_endpoints.ip}:${local.control_plane_endpoints.port}"
  admin_app_url     = length(kubernetes_service.admin_gui) > 0 ? "http://${local.admin_gui_endpoints.ip}:${local.admin_gui_endpoints.app_port}" : null
  admin_api_url     = length(kubernetes_service.admin_old_gui) > 0 ? "http://${local.admin_old_gui_endpoints.ip}:${local.admin_old_gui_endpoints.api_port}/api" : null
  admin_old_url     = length(kubernetes_service.admin_old_gui) > 0 ? "http://${local.admin_old_gui_endpoints.ip}:${local.admin_old_gui_endpoints.app_port}/" : null
  ingress_http_url  = var.ingress != null ? "${var.ingress.tls ? "https" : "http"}://${local.ingress_endpoint.ip}:${local.ingress_endpoint.http_port}" : ""
  ingress_grpc_url  = var.ingress != null ? "${var.ingress.tls ? "https" : "http"}://${local.ingress_endpoint.ip}:${local.ingress_endpoint.grpc_port}" : ""
}
