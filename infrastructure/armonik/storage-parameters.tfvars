# Needed storage for each ArmoniK data type
storage = {
  object         = "Redis"
  table          = "MongoDB"
  queue          = "Amqp"
  lease_provider = "MongoDB"
  shared         = "HostPath" # or "NFS" if you have an onpremise cluster
  # Mandatory: If you want execute the HTC Mock sample, you must set this parameter to "Redis", otherwise let it to ""
  external       = "Redis"
}

# Endpoints and secrets of storage resources
storage_endpoint_url = {
  mongodb  = {
    host   = "192.168.1.13"
    port   = "32670"
    secret = ""
  }
  redis    = {
    url    = "192.168.1.13:32041"
    secret = "redis-storage-secret"
  }
  activemq = {
    host   = "192.168.1.13"
    port   = "30423"
    secret = "activemq-storage-secret"
  }
  shared   = {
    host   = ""
    secret = ""
    # Path to external shared storage from which worker containers upload .dll
    path   = "/data"
  }
  external = {
    url    = "192.168.1.13:32041"
    secret = "external-redis-storage-secret"
  }
}