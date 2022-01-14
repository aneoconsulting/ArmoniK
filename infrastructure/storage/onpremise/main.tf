# List of storage to be created
module "storage" {
  source  = "../../modules/needed-storage"
  storage = var.storage
}

# MongoDB
module "mongodb" {
  count             = (contains(module.storage.list_storage, "mongodb") ? 1 : 0)
  source            = "./modules/mongodb"
  namespace         = var.namespace
  mongodb           = var.mongodb
  kubernetes_secret = var.storage_kubernetes_secrets.mongodb
}

# Redis
module "redis" {
  count             = (contains(module.storage.list_storage, "redis") ? 1 : 0)
  source            = "./modules/redis"
  namespace         = var.namespace
  redis             = var.redis
  kubernetes_secret = var.storage_kubernetes_secrets.redis
}

# ActiveMQ
module "activemq" {
  count             = (contains(module.storage.list_storage, "amqp") ? 1 : 0)
  source            = "./modules/activemq"
  namespace         = var.namespace
  activemq          = var.activemq
  kubernetes_secret = var.storage_kubernetes_secrets.activemq
}