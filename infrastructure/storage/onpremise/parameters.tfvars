# Namespace of ArmoniK storage
namespace = "armonik-storage"

# Storage resources to be created
storage = ["MongoDB", "Amqp", "Redis"]

# Kubernetes secrets for storage
storage_kubernetes_secrets = {
  mongodb  = "mongodb-storage-secret"
  redis    = "redis-storage-secret"
  activemq = "activemq-storage-secret"
}
