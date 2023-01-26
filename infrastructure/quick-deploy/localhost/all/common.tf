resource "random_string" "prefix" {
  length  = 5
  special = false
  upper   = false
  numeric = true
}

resource "kubernetes_namespace" "armonik" {
  metadata {
    name = var.namespace
  }
}

locals {
  prefix    = can(coalesce(var.prefix)) ? var.prefix : "armonik-${random_string.prefix.result}"
  namespace = kubernetes_namespace.armonik.metadata[0].name
}
