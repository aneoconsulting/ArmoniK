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
  image         = "symptoma/activemq"
  tag           = "5.16.3"
  node_selector = {}
}

# Parameters for MongoDB
mongodb = {
  image         = "mongo"
  tag           = "4.4.11"
  node_selector = {}
}

# Parameters for Redis
redis = {
  image         = "redis"
  tag           = "bullseye"
  node_selector = {}
}