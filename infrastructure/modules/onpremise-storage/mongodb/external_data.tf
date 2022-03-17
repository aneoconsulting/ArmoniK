# Node IP of MongoDB
data "external" "mongodb_node_ip" {
  depends_on  = [kubernetes_service.mongodb]
  program     = ["bash", "get_node_ip.sh", "mongodb", var.namespace]
  working_dir = "${var.working_dir}/utils/scripts"
}

# Node names
locals {
  # MongoDB
  mongodb_node_ip = try(tomap(data.external.mongodb_node_ip.result).node_ip, "")

  mongodb_load_balancer = (kubernetes_service.mongodb.spec.0.type == "LoadBalancer" ? {
    ip   = (kubernetes_service.mongodb.status.0.load_balancer.0.ingress.0.ip == "" || kubernetes_service.mongodb.status.0.load_balancer.0.ingress.0.ip == null ? kubernetes_service.mongodb.status.0.load_balancer.0.ingress.0.hostname : kubernetes_service.mongodb.status.0.load_balancer.0.ingress.0.ip)
    port = kubernetes_service.mongodb.spec.0.port.0.port
  } : {
    ip   = ""
    port = ""
  })

  mongodb_node_port = (local.mongodb_load_balancer.ip == "" && kubernetes_service.mongodb.spec.0.type == "NodePort" ? {
    ip   = local.mongodb_node_ip
    port = kubernetes_service.mongodb.spec.0.port.0.node_port
  } : {
    ip   = local.mongodb_load_balancer.ip
    port = local.mongodb_load_balancer.port
  })

  mongodb_endpoints = (local.mongodb_node_port.ip == "" && kubernetes_service.mongodb.spec.0.type == "ClusterIP" ? {
    ip   = kubernetes_service.mongodb.spec.0.cluster_ip
    port = kubernetes_service.mongodb.spec.0.port.0.port
  } : {
    ip   = local.mongodb_node_port.ip
    port = local.mongodb_node_port.port
  })

  mongodb_url = "mongodb://${local.mongodb_endpoints.ip}:${local.mongodb_endpoints.port}"
}

