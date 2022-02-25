locals {
  # ActiveMQ
  activemq_image         = lookup(var.activemq, "image", "symptoma/activemq")
  activemq_tag           = lookup(var.activemq, "tag", "5.16.3")
  activemq_node_selector = lookup(var.activemq, "node_selector", {})

  # MongoDB
  mongodb_image         = lookup(var.mongodb, "image", "mongo")
  mongodb_tag           = lookup(var.mongodb, "tag", "4.4.11")
  mongodb_node_selector = lookup(var.mongodb, "node_selector", {})

  # Redis
  redis_image         = lookup(var.redis, "image", "redis")
  redis_tag           = lookup(var.redis, "tag", "bullseye")
  redis_node_selector = lookup(var.redis, "node_selector", {})

  # Shared storage
  shared_storage_host_path         = lookup(var.shared_storage, "host_path", "/data")
  shared_storage_file_storage_type = lookup(var.shared_storage, "file_storage_type", "HostPath")
  shared_storage_file_server_ip    = lookup(var.shared_storage, "file_server_ip", "")
}