data "google_client_openid_userinfo" "current" {}

data "google_client_config" "current" {}

resource "random_string" "random_resources" {
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

data "google_kms_key_ring" "kms" {
  name     = var.kms.key_ring
  location = var.region
}

data "google_kms_crypto_key" "kms" {
  name     = var.kms.crypto_key
  key_ring = data.google_kms_key_ring.kms.id
}

locals {
  random_string = random_string.random_resources.result
  suffix        = var.suffix != null && var.suffix != "" ? var.suffix : local.random_string
  name          = local.suffix
  kms_key_id    = data.google_kms_crypto_key.kms.id
  labels = merge(var.labels, {
    env             = "dev"
    app             = "armonik"
    "create_by"     = split("@", data.google_client_openid_userinfo.current.email)[0]
    "creation_date" = "date-${null_resource.timestamp.triggers["date"]}"
  })
  node_pools_labels = { for key, value in var.gke.node_pools_labels : key => merge(local.labels, value) }
  node_pools_tags   = { for node_pool in coalesce(var.gke.node_pools, []) : node_pool["name"] => values(local.labels) }
  date              = <<-EOT
#!/bin/bash
set -e
DATE=$(date +%F-%H-%M-%S)
jq -n --arg date "$DATE" '{"date":$date}'
  EOT
}

module "gke" {
  source               = "../generated/infra-modules/kubernetes/gcp/gke"
  name                 = local.name
  network              = var.vpc.name
  subnetwork           = var.vpc.gke_subnet_name
  subnetwork_cidr      = var.vpc.gke_subnet_cidr_block
  ip_range_pods        = var.vpc.gke_subnet_pods_range_name
  ip_range_services    = var.vpc.gke_subnet_svc_range_name
  kubeconfig_path      = abspath(var.kubeconfig_file)
  service_account_name = "${local.name}-sa"
  database_encryption = [
    {
      state    = "ENCRYPTED"
      key_name = local.kms_key_id
    }
  ]
  cluster_resource_labels    = local.labels
  node_pools_tags            = local.node_pools_tags
  node_pools_labels          = local.node_pools_labels
  node_pools_resource_labels = local.node_pools_labels
  node_pools_taints          = var.gke.node_pools_taints
  private                    = !var.gke.enable_public_gke_access
  autopilot                  = var.gke.enable_gke_autopilot
  node_pools                 = var.gke.node_pools
}

