# Node IP of metrics-exporter pod
data "external" "partition_metrics_exporter_node_ip" {
  depends_on  = [kubernetes_service.partition_metrics_exporter]
  program     = ["bash", "get_node_ip.sh", "partition-metrics-exporter", var.namespace]
  working_dir = "${var.working_dir}/utils/scripts"
}

locals {
  node_selector_keys   = keys(var.node_selector)
  node_selector_values = values(var.node_selector)

  # Metrics exporter
  metrics_exporter_host = split(":", try(var.metrics_exporter_url, ""))[0]
  metrics_exporter_port = split(":", try(var.metrics_exporter_url, ""))[1]

  # Storage secrets
  activemq_certificates_secret      = try(var.storage_endpoint_url.activemq.certificates.secret, "")
  mongodb_certificates_secret       = try(var.storage_endpoint_url.mongodb.certificates.secret, "")
  redis_certificates_secret         = try(var.storage_endpoint_url.redis.certificates.secret, "")
  activemq_credentials_secret       = try(var.storage_endpoint_url.activemq.credentials.secret, "")
  mongodb_credentials_secret        = try(var.storage_endpoint_url.mongodb.credentials.secret, "")
  redis_credentials_secret          = try(var.storage_endpoint_url.redis.credentials.secret, "")
  activemq_certificates_ca_filename = try(var.storage_endpoint_url.activemq.certificates.ca_filename, "")
  mongodb_certificates_ca_filename  = try(var.storage_endpoint_url.mongodb.certificates.ca_filename, "")
  redis_certificates_ca_filename    = try(var.storage_endpoint_url.redis.certificates.ca_filename, "")
  activemq_credentials_username_key = try(var.storage_endpoint_url.activemq.credentials.username_key, "")
  mongodb_credentials_username_key  = try(var.storage_endpoint_url.mongodb.credentials.username_key, "")
  redis_credentials_username_key    = try(var.storage_endpoint_url.redis.credentials.username_key, "")
  activemq_credentials_password_key = try(var.storage_endpoint_url.activemq.credentials.password_key, "")
  mongodb_credentials_password_key  = try(var.storage_endpoint_url.mongodb.credentials.password_key, "")
  redis_credentials_password_key    = try(var.storage_endpoint_url.redis.credentials.password_key, "")

  # Endpoint urls storage
  activemq_host = try(var.storage_endpoint_url.activemq.host, "")
  activemq_port = try(var.storage_endpoint_url.activemq.port, "")
  mongodb_host  = try(var.storage_endpoint_url.mongodb.host, "")
  mongodb_port  = try(var.storage_endpoint_url.mongodb.port, "")
  redis_url     = try(var.storage_endpoint_url.redis.url, "")

  # Options of storage
  activemq_allow_host_mismatch = try(var.storage_endpoint_url.activemq.allow_host_mismatch, true)
  mongodb_allow_insecure_tls   = try(var.storage_endpoint_url.mongodb.allow_insecure_tls, true)
  redis_timeout                = try(var.storage_endpoint_url.redis.timeout, 3000)
  redis_ssl_host               = try(var.storage_endpoint_url.redis.ssl_host, "")

  # Credentials
  credentials = {
  for key, value in {
    Amqp__User        = local.activemq_credentials_secret != "" ? {
      key  = local.activemq_credentials_username_key
      name = local.activemq_credentials_secret
    } : { key = "", name = "" }
    Amqp__Password    = local.activemq_credentials_secret != "" ? {
      key  = local.activemq_credentials_password_key
      name = local.activemq_credentials_secret
    } : { key = "", name = "" }
    Redis__User       = local.redis_credentials_secret != "" ? {
      key  = local.redis_credentials_username_key
      name = local.redis_credentials_secret
    } : { key = "", name = "" }
    Redis__Password   = local.redis_credentials_secret != "" ? {
      key  = local.redis_credentials_password_key
      name = local.redis_credentials_secret
    } : { key = "", name = "" }
    MongoDB__User     = local.mongodb_credentials_secret != "" ? {
      key  = local.mongodb_credentials_username_key
      name = local.mongodb_credentials_secret
    } : { key = "", name = "" }
    MongoDB__Password = local.mongodb_credentials_secret != "" ? {
      key  = local.mongodb_credentials_password_key
      name = local.mongodb_credentials_secret
    } : { key = "", name = "" }
  } : key => value if !contains(values(value), "")
  }

  # Certificates
  certificates = {
  for key, value in {
    activemq = local.activemq_certificates_secret != "" ? {
      name        = "activemq-secret-volume"
      mount_path  = "/amqp"
      secret_name = local.activemq_certificates_secret
    } : { name = "", mount_path = "", secret_name = "" }
    redis    = local.redis_certificates_secret != "" ? {
      name        = "redis-secret-volume"
      mount_path  = "/redis"
      secret_name = local.redis_certificates_secret
    } : { name = "", mount_path = "", secret_name = "" }
    mongodb  = local.mongodb_certificates_secret != "" ? {
      name        = "mongodb-secret-volume"
      mount_path  = "/mongodb"
      secret_name = local.mongodb_certificates_secret
    } : { name = "", mount_path = "", secret_name = "" }
  } : key => value if !contains(values(value), "")
  }

  # Endpoint urls
  partition_metrics_exporter_node_ip = try(tomap(data.external.partition_metrics_exporter_node_ip.result).node_ip, "")
  load_balancer                      = (kubernetes_service.partition_metrics_exporter.spec.0.type == "LoadBalancer" ? {
    ip   = (kubernetes_service.partition_metrics_exporter.status.0.load_balancer.0.ingress.0.ip == "" ? kubernetes_service.partition_metrics_exporter.status.0.load_balancer.0.ingress.0.hostname : kubernetes_service.partition_metrics_exporter.status.0.load_balancer.0.ingress.0.ip)
    port = kubernetes_service.partition_metrics_exporter.spec.0.port.0.port
  } : {
    ip   = ""
    port = ""
  })

  node_port = (local.load_balancer.ip == "" && kubernetes_service.partition_metrics_exporter.spec.0.type == "NodePort" ? {
    ip   = local.partition_metrics_exporter_node_ip
    port = kubernetes_service.partition_metrics_exporter.spec.0.port.0.node_port
  } : {
    ip   = local.load_balancer.ip
    port = local.load_balancer.port
  })

  partition_metrics_exporter_endpoints = (local.node_port.ip == "" && kubernetes_service.partition_metrics_exporter.spec.0.type == "ClusterIP" ? {
    ip   = kubernetes_service.partition_metrics_exporter.spec.0.cluster_ip
    port = kubernetes_service.partition_metrics_exporter.spec.0.port.0.port
  } : {
    ip   = local.node_port.ip
    port = local.node_port.port
  })

  url = "http://${local.partition_metrics_exporter_endpoints.ip}:${local.partition_metrics_exporter_endpoints.port}"
}