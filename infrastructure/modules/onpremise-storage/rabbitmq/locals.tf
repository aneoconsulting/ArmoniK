locals {
  # rabbitmq node selector
  node_selector_keys   = keys(var.rabbitmq.node_selector)
  node_selector_values = values(var.rabbitmq.node_selector)
  plug                 = var.rabbitmq.protocol == "amqp1_0" ? ",rabbitmq_amqp1_0" : ""
}

