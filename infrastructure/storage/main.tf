# List of storage to be created
module "storage" {
  source  = "../modules/needed-storage"
  storage = var.storage
}

# MongoDB
module "mongodb" {
  count             = (contains(module.storage.list_storage, "mongodb") ? 1 : 0)
  source            = "./modules/onpremise/mongodb"
  namespace         = var.namespace
  mongodb           = var.mongodb
  kubernetes_secret = var.storage_kubernetes_secrets.mongodb
}

# Redis
module "redis" {
  count             = (contains(module.storage.list_storage, "redis") ? 1 : 0)
  source            = "./modules/onpremise/redis"
  namespace         = var.namespace
  redis             = var.redis
  kubernetes_secret = var.storage_kubernetes_secrets.redis
}

# ActiveMQ
module "activemq" {
  count             = (contains(module.storage.list_storage, "amqp") ? 1 : 0)
  source            = "./modules/onpremise/activemq"
  namespace         = var.namespace
  activemq          = var.activemq
  kubernetes_secret = var.storage_kubernetes_secrets.activemq
}

# AWS Elastic Block Store
module "aws_ebs" {
  count  = (contains(module.storage.list_storage, "aws_ebs") ? 1 : 0)
  source = "./modules/aws/ebs"
  ebs    = {
    availability_zone = var.aws_ebs.availability_zone
    size              = var.aws_ebs.size
    encrypted         = var.aws_ebs.encrypted
    kms_key_id        = var.aws_ebs.kms_key_id
    tags              = var.aws_ebs.tags
  }
}