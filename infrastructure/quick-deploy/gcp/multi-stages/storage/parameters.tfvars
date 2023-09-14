# Region
region = "europe-west1"

# SUFFIX
suffix = "main"

# Namespace
namespace = "armonik"

# Encrypt/decrypt
kms = {
  key_ring   = "armonik-europe-west1"
  crypto_key = "armonik-europe-west1"
}

# labels for gcp resources
labels = {}

# Table storage
mongodb = {
  node_selector = { service = "state-database" }
}

# Object storage
#memorystore = {
#  memory_size_gb = 20
#  auth_enabled   = true
#  connect_mode   = "PRIVATE_SERVICE_ACCESS"
#  redis_configs  = {
#    "maxmemory-gb"     = "18"
#    "maxmemory-policy" = "volatile-lru"
#  }
#  reserved_ip_range       = "10.0.0.0/24"
#  redis_version           = "REDIS_7_0"
#  tier                    = "STANDARD_HA"
#  transit_encryption_mode = "SERVER_AUTHENTICATION"
#  replica_count           = 3
#  read_replicas_mode      = "READ_REPLICAS_ENABLED"
#}
gcs_os = {}