# Kubernetes namespace
namespace                     = "armonik"
external_data_plane_namespace = "external-data-plane"


# Uncomment this to have minio S3 enabled instead of hostpath shared_storage
#minio_s3_fs = {}

# Shared storage
shared_storage = {
  host_path         = "/data"
  file_storage_type = "HostPath" # or "NFS"
  file_server_ip    = ""
}

# Parameters for ActiveMQ
/*activemq = {
  image              = "symptoma/activemq"
  tag                = "5.18.0"
  node_selector      = {}
  image_pull_secrets = ""
}

# Parameters for MongoDB
mongodb = {
  image              = "mongo"
  tag                = "6.0.7"
  node_selector      = {}
  image_pull_secrets = ""
  replicas_number    = 1
}

# Object storage
# Uncomment either the `redis` or the `minio` parameter
# Parameters for Redis
redis = {
  image              = "redis"
  tag                = "7.0.12-alpine3.18"
  node_selector      = {}
  image_pull_secrets = ""
  max_memory         = "12000mb"
}
*/
# Parameters for minio
/*minio = {
  host               = "minio"
  default_bucket     = "minioBucket"
  image              = "minio/minio"
  tag                = "RELEASE.2023-07-18T17-49-40Z"
  image_pull_secrets = ""
  node_selector      = {}
}*/
