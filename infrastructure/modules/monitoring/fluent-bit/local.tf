locals {
  # Fluent-bit
  fluent_bit_container_name = lookup(var.fluent_bit, "container_name", "fluent-bit")
  fluent_bit_image          = lookup(var.fluent_bit, "image", "fluent/fluent-bit")
  fluent_bit_tag            = lookup(var.fluent_bit, "tag", "1.3.11")
  fluent_bit_is_daemonset   = tobool(lookup(var.fluent_bit, "is_daemonset", false))
  fluent_bit_http_server    = lookup(var.fluent_bit, "http_server", "Off")
  fluent_bit_http_port      = lookup(var.fluent_bit, "http_port", "")
  fluent_bit_read_from_head = lookup(var.fluent_bit, "read_from_head", "On")
  fluent_bit_read_from_tail = lookup(var.fluent_bit, "read_from_tail", "Off")

  # Seq
  seq_host = lookup(var.seq, "host", "")
  seq_port = lookup(var.seq, "port", "")
  seq_use  = tobool(lookup(var.seq, "use", false))

  # CloudWatch
  cloudwatch_cluster_name = lookup(var.cloudwatch, "cluster_name", "")
  cloudwatch_region       = lookup(var.cloudwatch, "region", "")
  cloudwatch_ci_version   = lookup(var.cloudwatch, "ci_version", "")
  cloudwatch_use          = tobool(lookup(var.cloudwatch, "use", false))
}