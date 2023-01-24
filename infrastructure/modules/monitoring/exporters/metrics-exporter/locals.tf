# Node IP of metrics-exporter pod
data "external" "metrics_exporter_node_ip" {
  depends_on  = [kubernetes_service.metrics_exporter]
  program     = ["bash", "get_node_ip.sh", "metrics-exporter", var.namespace]
  working_dir = "${var.working_dir}/utils/scripts"
}

locals {
  node_selector_keys   = keys(var.node_selector)
  node_selector_values = values(var.node_selector)

  # Storage secrets
  mongodb_certificates_secret = try(var.storage_endpoint_url.mongodb.certificates.secret, "")
  mongodb_credentials_secret  = try(var.storage_endpoint_url.mongodb.credentials.secret, "")
  mongodb_endpoints_secret    = try(var.storage_endpoint_url.mongodb.endpoints.secret, "")

  # Credentials
  credentials = {
    for key, value in {
      MongoDB__User = local.mongodb_credentials_secret != "" ? {
        key  = "username"
        name = local.mongodb_credentials_secret
      } : { key = "", name = "" }
      MongoDB__Password = local.mongodb_credentials_secret != "" ? {
        key  = "password"
        name = local.mongodb_credentials_secret
      } : { key = "", name = "" }
      MongoDB__Host = local.mongodb_endpoints_secret != "" ? {
        key  = "host"
        name = local.mongodb_endpoints_secret
      } : { key = "", name = "" }
      MongoDB__Port = local.mongodb_endpoints_secret != "" ? {
        key  = "port"
        name = local.mongodb_endpoints_secret
      } : { key = "", name = "" }
    } : key => value if !contains(values(value), "")
  }

  # Certificates
  certificates = {
    for key, value in {
      mongodb = local.mongodb_certificates_secret != "" ? {
        name        = "mongodb-secret-volume"
        mount_path  = "/mongodb"
        secret_name = local.mongodb_certificates_secret
      } : { name = "", mount_path = "", secret_name = "" }
    } : key => value if !contains(values(value), "")
  }

  # Endpoint urls
  metrics_exporter_node_ip = try(tomap(data.external.metrics_exporter_node_ip.result).node_ip, "")
  load_balancer = (kubernetes_service.metrics_exporter.spec.0.type == "LoadBalancer" ? {
    ip   = (kubernetes_service.metrics_exporter.status.0.load_balancer.0.ingress.0.ip == "" ? kubernetes_service.metrics_exporter.status.0.load_balancer.0.ingress.0.hostname : kubernetes_service.metrics_exporter.status.0.load_balancer.0.ingress.0.ip)
    port = kubernetes_service.metrics_exporter.spec.0.port.0.port
    } : {
    ip   = ""
    port = ""
  })

  node_port = (local.load_balancer.ip == "" && kubernetes_service.metrics_exporter.spec.0.type == "NodePort" ? {
    ip   = local.metrics_exporter_node_ip
    port = kubernetes_service.metrics_exporter.spec.0.port.0.node_port
    } : {
    ip   = local.load_balancer.ip
    port = local.load_balancer.port
  })

  metrics_exporter_endpoints = (local.node_port.ip == "" && kubernetes_service.metrics_exporter.spec.0.type == "ClusterIP" ? {
    ip   = kubernetes_service.metrics_exporter.spec.0.cluster_ip
    port = kubernetes_service.metrics_exporter.spec.0.port.0.port
    } : {
    ip   = local.node_port.ip
    port = local.node_port.port
  })

  url = "http://${local.metrics_exporter_endpoints.ip}:${local.metrics_exporter_endpoints.port}"
}