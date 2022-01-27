# Namespace of ArmoniK storage
namespace = "armonik-storage"

# Profile
aws_profile = "default"

# Region
aws_region = "eu-west-3"

# Storage resources to be created
# Warning: the allowed storage for ArmoniK are defined in:
# "../../modules/needed-storage/storage_for_each_armonik_data.tf"
storage = ["MongoDB", "Amqp", "Redis"]

# Kubernetes secrets for storage
storage_kubernetes_secrets = {
  mongodb  = "mongodb-storage-secret"
  redis    = "redis-storage-secret"
  activemq = "activemq-storage-secret"
}
