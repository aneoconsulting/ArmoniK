locals {
  # ActiveMQ node selector
  node_selector_keys   = keys(var.redis.node_selector)
  node_selector_values = values(var.redis.node_selector)
}