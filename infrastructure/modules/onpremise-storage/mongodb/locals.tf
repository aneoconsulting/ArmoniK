locals {
  # ActiveMQ node selector
  node_selector_keys   = keys(var.mongodb.node_selector)
  node_selector_values = values(var.mongodb.node_selector)
}