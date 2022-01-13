# Node IP of Redis pod
data "external" "redis_node_ip" {
  depends_on = [module.redis]
  program     = ["bash", "get_node_ip.sh", "redis", var.namespace]
  working_dir = "../../utils/scripts"
}

# Node IP of MongoDB pod
data "external" "mongodb_node_ip" {
  depends_on = [module.mongodb]
  program     = ["bash", "get_node_ip.sh", "mongodb", var.namespace]
  working_dir = "../../utils/scripts"
}

# Node IP of ActiveMQ pod
data "external" "activemq_node_ip" {
  depends_on = [module.activemq]
  program     = ["bash", "get_node_ip.sh", "activemq", var.namespace]
  working_dir = "../../utils/scripts"
}

# Node names
locals {
  redis_node_ip    = lookup(tomap(data.external.redis_node_ip.result), "node_ip", "")
  mongodb_node_ip  = lookup(tomap(data.external.mongodb_node_ip.result), "node_ip", "")
  activemq_node_ip = lookup(tomap(data.external.activemq_node_ip.result), "node_ip", "")
}

