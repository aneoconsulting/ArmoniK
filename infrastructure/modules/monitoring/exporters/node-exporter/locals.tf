locals {
  node_selector_keys   = keys(var.node_selector)
  node_selector_values = values(var.node_selector)
}
