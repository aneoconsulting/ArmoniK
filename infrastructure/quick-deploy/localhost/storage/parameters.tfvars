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
  tag                = "5.16.4"
  node_selector      = {}
  image_pull_secrets = ""
}

# Parameters for MongoDB
mongodb = {
  image              = "mongo"
  tag                = "5.0.9"
  node_selector      = {}
  image_pull_secrets = ""
}

# Parameters for Redis
redis = {
  image              = "redis"
  tag                = "6.2.7"
  node_selector      = {}
  image_pull_secrets = ""
  max_memory         = "12000mb"
}