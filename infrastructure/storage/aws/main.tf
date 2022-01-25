# Redis
module "redis" {
  count             = 1
  source            = "./modules/redis"
  namespace         = var.namespace
  redis             = var.redis
  kubernetes_secret = var.storage_kubernetes_secrets.redis
}

# ActiveMQ
module "activemq" {
  count             = 1
  source            = "./modules/activemq"
  namespace         = var.namespace
  activemq          = var.activemq
  kubernetes_secret = var.storage_kubernetes_secrets.activemq
}