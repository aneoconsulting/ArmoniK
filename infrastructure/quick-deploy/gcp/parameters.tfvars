# GKE
gke = {
  enable_public_gke_access = true
  # Zonal cluster: one node per pool at start. On a regional cluster, every pool starts with initial_node_count
  # nodes in each of the 3 zones, and the small pools never scale down: the GKE system DaemonSets alone request
  # more than half of an e2-medium, above the threshold under which the autoscaler removes a node
  regional = false
  zones    = ["europe-west1-b"]
  # Autoscaling bounds over all the zones of each pool (min_count and max_count would be per zone).
  # initial_node_count is per zone
  node_pools = {
    workers = {
      machine_type       = "e2-standard-8"
      image_type         = "COS_CONTAINERD"
      max_pods_per_node  = 110
      initial_node_count = 1
      total_min_count    = 0
      total_max_count    = 1000
      location_policy    = "BALANCED" # or ANY
      disk_size_gb       = 100
      disk_type          = "pd-standard"
      spot               = true
      labels             = { service = "workers" }
      taints = [
        {
          key    = "service"
          value  = "workers"
          effect = "NO_SCHEDULE"
        }
      ]
    }
    # Everything but the partitions: operators, control plane, ingress, PostgreSQL, monitoring
    services = {
      machine_type       = "e2-standard-4"
      image_type         = "COS_CONTAINERD"
      max_pods_per_node  = 110
      initial_node_count = 1
      total_min_count    = 1
      total_max_count    = 10
      location_policy    = "BALANCED" # or ANY
      disk_size_gb       = 100
      disk_type          = "pd-standard"
      spot               = false
      labels             = { service = "services" }
    }
  }
}

kms = {
  key_ring   = "armonik-europe-west1"
  crypto_key = "armonik-europe-west1"
}

# Logging level
logging_level = "Information"

# Queue: ActiveMQ in the cluster instead of Pub/Sub
# activemq = true

# Object storage: Memorystore for Valkey instead of GCS
#memorystore = {
#  node_type      = "HIGHMEM_MEDIUM"
#  engine_version = "VALKEY_8_0"
#  replica_count  = 1
#  engine_configs = {
#    "maxmemory-policy" = "volatile-lru"
#  }
#}

# Partitions added to the chart's own (default, stream, htcmock)
partitions = {
  # Partition for the pymonik worker
  pymonik = {
    image        = "docker.io/dockerhubaneo/harmonic_snake"
    tag          = "python-3.10.12"
    cpu          = "50m"
    cpu_limit    = "1000m"
    memory       = "1024Mi"
    max_replicas = 100
  }
}

# Values of the armonik chart, over those of the quick deploy
armonik_values = <<-EOT
  compute-plane:
    partitionCommon:
      hpa:
        maxReplicaCount: 100
      agent:
        resources:
          requests: {cpu: 500m, memory: 256Mi}
          limits: {cpu: 2000m, memory: 2048Mi}
      worker:
        resources:
          requests: {cpu: 500m, memory: 512Mi}
          limits: {cpu: 1000m, memory: 1024Mi}
  conf:
    core:
      env:
        Amqp__MaxPriority: "10"
        Amqp__MaxRetries: "5"
        Redis__Timeout: "3000"
        Redis__TtlTimeSpan: "1.00:00:00" # 1 day retention
        Submitter__DeletePayload: "true"
    control:
      env:
        Submitter__MaxErrorAllowed: "50"
    worker:
      env:
        target_zip_path: /tmp
EOT
