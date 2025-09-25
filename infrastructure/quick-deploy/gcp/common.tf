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

data "external" "static_timestamp" {
  program = ["sh", "-c", <<-EOT
      echo "{\"date\": \"$(date +%F-%H-%M-%S)\"}"
    EOT
  ]
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
  gke_name   = local.prefix
  kms_key_id = data.google_kms_crypto_key.kms.id
  namespace  = kubernetes_namespace.armonik.metadata[0].name
  labels = merge({
    "application"        = "armonik"
    "deployment_version" = local.prefix
    "created_by"         = split("@", data.google_client_openid_userinfo.current.email)[0]
    "creation_date"      = "date-${null_resource.timestamp.triggers["date"]}"
  }, var.labels)
  node_pools_labels = { for key, value in var.gke.node_pools_labels : key => merge(local.labels, value) }
  node_pools_tags   = { for node_pool in coalesce(var.gke.node_pools, []) : node_pool["name"] => toset(values(local.labels)) }
}