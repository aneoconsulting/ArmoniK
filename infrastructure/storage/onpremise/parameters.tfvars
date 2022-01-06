# Namespace of ArmoniK storage
namespace = "armonik-storage"

# Storage resources to be created
# Warning: the allowed storage for ArmoniK are defined in:
# "../../modules/needed-storage/allowed_storage.tf"
storage = {
  object         = "MongoDB"
  table          = "MongoDB"
  queue          = "MongoDB"
  lease_provider = "MongoDB"
  shared         = ""
  external       = ""
}

# Kubernetes secrets for storage
storage_kubernetes_secrets = {
  mongodb  = ""
  redis    = "redis-storage-secret"
  activemq = "activemq-storage-secret"
}
