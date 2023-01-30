locals {
  node_selector_keys   = keys(var.minioconfig.node_selector)
  node_selector_values = values(var.minioconfig.node_selector)
}
