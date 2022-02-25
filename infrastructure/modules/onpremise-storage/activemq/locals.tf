locals {
  # ActiveMQ node selector
  node_selector_keys   = keys(var.activemq.node_selector)
  node_selector_values = values(var.activemq.node_selector)
}