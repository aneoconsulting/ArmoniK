data "kubernetes_secret" "deployed_object_storage" {
  metadata {
    name      = local.secrets.deployed_object_storage_secret
    namespace = var.namespace
  }
}

data "kubernetes_secret" "shared_storage" {
  metadata {
    name      = local.secrets.shared_storage_secret
    namespace = var.namespace
  }
}

data "kubernetes_secret" "metrics_exporter" {
  metadata {
    name      = local.secrets.metrics_exporter_secret
    namespace = var.namespace
  }
}

data "kubernetes_secret" "partition_metrics_exporter" {
  metadata {
    name      = local.secrets.partition_metrics_exporter_secret
    namespace = var.namespace
  }
}

data "kubernetes_secret" "fluent_bit" {
  metadata {
    name      = local.secrets.fluent_bit_secret
    namespace = var.namespace
  }
}

data "kubernetes_secret" "seq" {
  metadata {
    name      = local.secrets.seq_secret
    namespace = var.namespace
  }
}

data "kubernetes_secret" "grafana" {
  metadata {
    name      = local.secrets.grafana_secret
    namespace = var.namespace
  }
}

data "kubernetes_secret" "s3_object_storage_endpoints" {
  count = lower(var.object_storage_adapter) == "s3" ? 1 : 0
  metadata {
    name      = local.secrets.s3_object_storage_secret
    namespace = var.namespace
  }
}