resource "kubernetes_secret" "activemq_endpoints" {
  metadata {
    name      = "activemq-endpoints"
    namespace = var.namespace
  }
  data = {
    host    = trim(split(":", aws_mq_broker.mq.instances.0.endpoints.1).1, "//")
    port    = tonumber(split(":", aws_mq_broker.mq.instances.0.endpoints.1).2)
    url     = aws_mq_broker.mq.instances.0.endpoints.1
    web-url = aws_mq_broker.mq.instances.0.console_url
  }
}