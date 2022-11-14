resource "random_string" "random_resources" {
  length  = 5
  special = false
  upper   = false
  numeric  = true
}

locals {
  nameOverride         = "${var.name}-${var.namespace}-${random_string.random_resources.result}"
  fullnameOverride     = "${var.name}-${var.namespace}-fullname-${random_string.random_resources.result}"
  node_selector_keys   = keys(var.node_selector)
  node_selector_values = values(var.node_selector)

  node_selector = {
    nodeSelector = var.node_selector
  }

  tolerations = {
    tolerations = [
      for index in range(0, length(local.node_selector_keys)) : {
        key      = local.node_selector_keys[index]
        operator = "Equal"
        value    = local.node_selector_values[index]
        effect   = "NoSchedule"
      }
    ]
  }
}