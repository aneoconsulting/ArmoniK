data "kubernetes_secret" "deployed_object_storage" {
  metadata {
    name      = local.secrets.deployed_object_storage_secret
    namespace = var.namespace
  }
}

data "kubernetes_secret" "deployed_table_storage" {
  metadata {
    name      = local.secrets.deployed_table_storage_secret
    namespace = var.namespace
  }
}

data "kubernetes_secret" "deployed_queue_storage" {
  metadata {
    name      = local.secrets.deployed_queue_storage_secret
    namespace = var.namespace
  }
}

data "kubernetes_secret" "shared_storage" {
  metadata {
    name      = local.secrets.shared_storage
    namespace = var.namespace
  }
}

data "kubernetes_secret" "metrics_exporter" {
  metadata {
    name      = local.secrets.metrics_exporter
    namespace = var.namespace
  }
}

data "kubernetes_secret" "partition_metrics_exporter" {
  metadata {
    name      = local.secrets.partition_metrics_exporter
    namespace = var.namespace
  }
}

data "kubernetes_secret" "fluent_bit" {
  metadata {
    name      = local.secrets.fluent_bit
    namespace = var.namespace
  }
}

data "kubernetes_secret" "seq" {
  metadata {
    name      = local.secrets.seq
    namespace = var.namespace
  }
}

data "kubernetes_secret" "grafana" {
  metadata {
    name      = local.secrets.grafana
    namespace = var.namespace
  }
}