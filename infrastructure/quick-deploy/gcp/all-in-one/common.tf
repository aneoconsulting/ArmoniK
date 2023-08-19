data "google_client_openid_userinfo" "current" {}

data "google_client_config" "current" {}

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

resource "kubernetes_namespace" "armonik" {
  metadata {
    name = var.namespace
  }
  depends_on = [module.gke]
}

locals {
  prefix    = try(coalesce(var.prefix), "armonik-${random_string.prefix.result}")
  gke_name  = "${local.prefix}-gke"
  namespace = kubernetes_namespace.armonik.metadata[0].name
  labels    = merge({
    "application"        = "armonik"
    "deployment_version" = local.prefix
    "created_by"         = split("@", data.google_client_openid_userinfo.current.email)[0]
    "creation_date"      = null_resource.timestamp.triggers["date"]
  }, var.labels)
  date = <<-EOT
#!/bin/bash
set -e
DATE=$(date +%F-%H-%M-%S)
jq -n --arg date "$DATE" '{"date":$date}'
  EOT
}