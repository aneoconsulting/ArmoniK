resource "random_string" "random_resources" {
  length  = 5
  special = false
  upper   = false
}

locals {
  tag          = var.tag != "" ? var.tag : random_string.random_resources.result
  cluster_name = "${local.tag}-armonik-eks"
}

