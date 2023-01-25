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
  secrets = {
    mongodb = {
      certificates_secret = "mongodb-user-certificates"
      credentials_secret  = "mongodb-user"
      endpoints_secret    = "mongodb-endpoints"
      ca_filename         = "/mongodb/chain.pem"
    }
  }

  # Credentials
  credentials = {
    MongoDB__User = {
      key  = "username"
      name = local.secrets.mongodb.credentials_secret
    }
    MongoDB__Password = {
      key  = "password"
      name = local.secrets.mongodb.credentials_secret
    }
    MongoDB__Host = {
      key  = "host"
      name = local.secrets.mongodb.endpoints_secret
    }
    MongoDB__Port = {
      key  = "port"
      name = local.secrets.mongodb.endpoints_secret
    }
  }

  # Certificates
  certificates = {
    mongodb = {
      name        = "mongodb-secret-volume"
      mount_path  = "/mongodb"
      secret_name = local.secrets.mongodb.certificates_secret
    }
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