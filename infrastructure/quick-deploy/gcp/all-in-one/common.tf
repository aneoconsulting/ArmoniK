data "google_client_openid_userinfo" "current" {}

data "google_client_config" "current" {}

data "google_compute_zones" "available" {}

data "google_kms_key_ring" "kms" {
  name     = var.kms.key_ring
  location = var.region
}

data "google_kms_crypto_key" "kms" {
  name     = var.kms.crypto_key
  key_ring = data.google_kms_key_ring.kms.id
}

resource "random_string" "prefix" {
  length  = 5
  special = false
  upper   = false
  numeric = true
}

resource "local_file" "date_sh" {
  filename = "${path.module}/generated/date.sh"
  content  = local.date
}

data "external" "static_timestamp" {
  program     = ["bash", "date.sh"]
  working_dir = "${path.module}/generated"
  depends_on  = [local_file.date_sh]
}

resource "null_resource" "timestamp" {
  triggers = {
    date = data.external.static_timestamp.result.date
  }
  lifecycle {
    ignore_changes = [triggers]
  }
}

locals {
  prefix     = try(coalesce(var.prefix), "armonik-${random_string.prefix.result}")
  gke_name   = "${local.prefix}-gke"
  kms_key_id = data.google_kms_crypto_key.kms.id
  namespace  = kubernetes_namespace.armonik.metadata[0].name
  labels = merge({
    "application"        = "armonik"
    "deployment_version" = local.prefix
    "created_by"         = split("@", data.google_client_openid_userinfo.current.email)[0]
    "creation_date"      = null_resource.timestamp.triggers["date"]
  }, var.labels)
  node_pool_labels = { all = local.labels, default-node-pool = local.labels }
  node_pool_tags   = { all = values(local.labels), default-node-pool = values(local.labels) }
  date             = <<-EOT
#!/bin/bash
set -e
DATE=$(date +%F-%H-%M-%S)
jq -n --arg date "$DATE" '{"date":$date}'
  EOT
}