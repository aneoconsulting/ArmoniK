resource "random_string" "prefix" {
  length  = 5
  special = false
  upper   = false
  numeric = true
}

locals {
  prefix    = try(coalesce(var.prefix), "armonik-${random_string.prefix.result}")
  namespace = var.namespace
}
