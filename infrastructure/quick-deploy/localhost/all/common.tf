resource "random_string" "prefix" {
  length  = 5
  special = false
  upper   = false
  numeric = true
}

locals {
  prefix    = can(coalesce(var.prefix)) ? var.prefix : "armonik-${random_string.prefix.result}"
  namespace = var.namespace
}
