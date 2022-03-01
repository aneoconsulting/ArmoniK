locals {
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