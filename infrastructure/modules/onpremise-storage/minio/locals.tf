locals {
  node_selector_keys   = keys(var.minio.node_selector)
  node_selector_values = values(var.minio.node_selector)
  port                 = 9000
  console_port         = 9001
}
