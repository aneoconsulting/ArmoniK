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


# Node IP of ingress pod
data "external" "ingress_node_ip" {
  count       = var.ingress != null || var.ingress != {} ? 1 : 0
  depends_on  = [kubernetes_service.ingress.0]
  program     = ["bash", "get_node_ip.sh", "ingress", var.namespace]
  working_dir = "${var.working_dir}/utils/scripts"
}

locals {
  ingress_node_ip = try(tomap(data.external.ingress_node_ip.0.result).node_ip, "")

  ingress_load_balancer = (var.ingress != null || var.ingress != {} ? kubernetes_service.ingress.0.spec.0.type == "LoadBalancer" : false) ? {
    ip        = (kubernetes_service.ingress.0.status.0.load_balancer.0.ingress.0.ip == "" ? kubernetes_service.ingress.0.status.0.load_balancer.0.ingress.0.hostname : kubernetes_service.ingress.0.status.0.load_balancer.0.ingress.0.ip)
    http_port = var.ingress.http_port
    grpc_port = var.ingress.grpc_port
  } : {
    ip        = ""
    http_port = ""
    grpc_port = ""
  }

  ingress_node_port = (var.ingress != null || var.ingress != {} ? local.ingress_load_balancer.ip == "" && kubernetes_service.ingress.0.spec.0.type == "NodePort" : false) ? {
    ip        = local.ingress_node_ip
    http_port = element(kubernetes_service.ingress.0.spec.0.port[*].node_port, 0)
    grpc_port = element(kubernetes_service.ingress.0.spec.0.port[*].node_port, 1)
  } : {
    ip        = local.ingress_load_balancer.ip
    http_port = local.ingress_load_balancer.http_port
    grpc_port = local.ingress_load_balancer.grpc_port
  }

  ingress_endpoint = (var.ingress != null || var.ingress != {} ? local.ingress_node_port.ip == "" && kubernetes_service.ingress.0.spec.0.type == "ClusterIP" : false) ? {
    ip        = kubernetes_service.ingress.0.spec.0.cluster_ip
    http_port = var.ingress.http_port
    grpc_port = var.ingress.grpc_port
  } : {
    ip        = local.ingress_node_port.ip
    http_port = local.ingress_node_port.http_port
    grpc_port = local.ingress_node_port.grpc_port
  }

  ingress_http_url = var.ingress != null || var.ingress != {} ? "${var.ingress.tls ? "https" : "http"}://${local.ingress_endpoint.ip}:${local.ingress_endpoint.http_port}" : ""
  ingress_grpc_url = var.ingress != null || var.ingress != {} ? "${var.ingress.tls ? "https" : "http"}://${local.ingress_endpoint.ip}:${local.ingress_endpoint.grpc_port}" : ""
}
