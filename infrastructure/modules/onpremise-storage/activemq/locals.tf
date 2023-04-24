locals {
  # ActiveMQ node selector
  node_selector_keys    = keys(var.activemq.node_selector)
  node_selector_values  = values(var.activemq.node_selector)
  adapter_class_name    = "ArmoniK.Core.Adapters.Amqp.QueueBuilder"
  adapter_absolute_path = "/adapters/queue/amqp/ArmoniK.Core.Adapters.Amqp.dll"
  engine_type           = "ActiveMQ"

}