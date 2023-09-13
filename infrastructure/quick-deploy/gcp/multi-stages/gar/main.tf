data "google_client_openid_userinfo" "current" {}

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
  kms_key_id    = data.google_kms_crypto_key.kms.id
  labels = merge(var.labels, {
    env             = "dev"
    app             = "armonik"
    "create_by"     = split("@", data.google_client_openid_userinfo.current.email)[0]
    "creation_date" = null_resource.timestamp.triggers["date"]
  })
  date = <<-EOT
#!/bin/bash
set -e
DATE=$(date +%F-%H-%M-%S)
jq -n --arg date "$DATE" '{"date":$date}'
  EOT
}

module "gar" {
  source        = "../generated/infra-modules/container-registry/gcp/artifact-registry"
  docker_images = var.gar
  name          = "docker-registry-${local.suffix}"
  description   = "All docker images for ArmoniK"
  kms_key_name  = local.kms_key_id
  labels        = local.labels
}