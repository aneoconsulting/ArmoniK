# Kubernetes namespace
namespace = "armonik"

# Shared storage
shared_storage = {
  host_path         = "/data"
  file_storage_type = "HostPath" # or "NFS"
  file_server_ip    = ""
}

# Parameters for ActiveMQ
activemq = {
  image              = "symptoma/activemq"
  tag                = "5.17.0"
  node_selector      = {}
  image_pull_secrets = ""
}

# Parameters for MongoDB
mongodb = {
  image              = "mongo"
  tag                = "6.0.1"
  node_selector      = {}
  image_pull_secrets = ""
}

# Object storage
# Uncomment either the `redis` or the `minio` parameter
# Parameters for Redis
redis = {
  image              = "redis"
  tag                = "7.0.8"
  node_selector      = {}
  image_pull_secrets = ""
  max_memory         = "12000mb"
}

# Parameters for minio
/*minio = {
  host               = "minio"
  default_bucket     = "minioBucket"
  image              = "minio/minio"
  tag                = "RELEASE.2023-02-10T18-48-39Z"
  image_pull_secrets = ""
  node_selector      = {}
}*/
