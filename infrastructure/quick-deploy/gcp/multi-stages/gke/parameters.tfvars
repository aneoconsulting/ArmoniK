# Region
region = "europe-west1"

# SUFFIX
suffix = "main"

kms = {
  key_ring   = "armonik-europe-west1"
  crypto_key = "armonik-europe-west1"
}

# GKE
gke = {
  enable_public_gke_access = true
  enable_gke_autopilot     = false
  node_pools_labels = {
    workers = {
      service = "workers"
    }
    metrics = {
      service = "metrics"
    }
    control-plane = {
      service = "control-plane"
    }
    monitoring = {
      service = "monitoring"
    }
    state-database = {
      service = "state-database"
    }
    others = {
      service = "others"
    }
  }
  node_pools_taints = {
    workers = [
      {
        key    = "service"
        value  = "workers"
        effect = "NO_SCHEDULE"
      }
    ]
    metrics = [
      {
        key    = "service"
        value  = "metrics"
        effect = "NO_SCHEDULE"
      }
    ]
    control-plane = [
      {
        key    = "service"
        value  = "control-plane"
        effect = "NO_SCHEDULE"
      }
    ]
    monitoring = [
      {
        key    = "service"
        value  = "monitoring"
        effect = "NO_SCHEDULE"
      }
    ]
    state-database = [
      {
        key    = "service"
        value  = "state-database"
        effect = "NO_SCHEDULE"
      }
    ]
  }
  node_pools = [
    {
      name             = "workers"
      machine_type     = "e2-standard-8"
      image_type       = "COS_CONTAINERD"
      min_cpu_platform = ""
      # or see https://cloud.google.com/compute/docs/instances/specify-min-cpu-platform#availablezones
      autoscaling                 = true
      node_count                  = null # should not be used alongside autoscaling
      max_pods_per_node           = 110
      initial_node_count          = 1
      min_count                   = 0          # per zone. It is null if used alongside total_min_count
      max_count                   = 1000       # per zone. It is null if used alongside total_max_count
      total_min_count             = 0          # per NodePool
      total_max_count             = 1000       # per NodePool
      location_policy             = "BALANCED" # or ANY
      auto_repair                 = true
      auto_upgrade                = true
      enable_gcfs                 = false
      enable_gvnic                = false
      logging_variant             = "DEFAULT"
      local_ssd_count             = 0
      disk_size_gb                = 100
      disk_type                   = "pd-standard"
      spot                        = true
      boot_disk_kms_key           = ""
      enable_secure_boot          = false
      enable_integrity_monitoring = true
    },
    {
      name             = "metrics"
      machine_type     = "e2-medium"
      image_type       = "COS_CONTAINERD"
      min_cpu_platform = ""
      # or see https://cloud.google.com/compute/docs/instances/specify-min-cpu-platform#availablezones
      autoscaling                 = true
      node_count                  = null # should not be used alongside autoscaling
      max_pods_per_node           = 110
      initial_node_count          = 1
      min_count                   = 1          # per zone. It is null if used alongside total_min_count
      max_count                   = 5          # per zone. It is null if used alongside total_max_count
      total_min_count             = 1          # per NodePool
      total_max_count             = 5          # per NodePool
      location_policy             = "BALANCED" # or ANY
      auto_repair                 = true
      auto_upgrade                = true
      enable_gcfs                 = false
      enable_gvnic                = false
      logging_variant             = "DEFAULT"
      local_ssd_count             = 0
      disk_size_gb                = 100
      disk_type                   = "pd-standard"
      spot                        = false
      boot_disk_kms_key           = ""
      enable_secure_boot          = false
      enable_integrity_monitoring = true
    },
    {
      name             = "control-plane"
      machine_type     = "e2-medium"
      image_type       = "COS_CONTAINERD"
      min_cpu_platform = ""
      # or see https://cloud.google.com/compute/docs/instances/specify-min-cpu-platform#availablezones
      autoscaling                 = true
      node_count                  = null # should not be used alongside autoscaling
      max_pods_per_node           = 110
      initial_node_count          = 1
      min_count                   = 1          # per zone. It is null if used alongside total_min_count
      max_count                   = 10         # per zone. It is null if used alongside total_max_count
      total_min_count             = 1          # per NodePool
      total_max_count             = 10         # per NodePool
      location_policy             = "BALANCED" # or ANY
      auto_repair                 = true
      auto_upgrade                = true
      enable_gcfs                 = false
      enable_gvnic                = false
      logging_variant             = "DEFAULT"
      local_ssd_count             = 0
      disk_size_gb                = 100
      disk_type                   = "pd-standard"
      spot                        = false
      boot_disk_kms_key           = ""
      enable_secure_boot          = false
      enable_integrity_monitoring = true
    },
    {
      name             = "monitoring"
      machine_type     = "e2-medium"
      image_type       = "COS_CONTAINERD"
      min_cpu_platform = ""
      # or see https://cloud.google.com/compute/docs/instances/specify-min-cpu-platform#availablezones
      autoscaling                 = true
      node_count                  = null # should not be used alongside autoscaling
      max_pods_per_node           = 110
      initial_node_count          = 1
      min_count                   = 1          # per zone. It is null if used alongside total_min_count
      max_count                   = 5          # per zone. It is null if used alongside total_max_count
      total_min_count             = 1          # per NodePool
      total_max_count             = 5          # per NodePool
      location_policy             = "BALANCED" # or ANY
      auto_repair                 = true
      auto_upgrade                = true
      enable_gcfs                 = false
      enable_gvnic                = false
      logging_variant             = "DEFAULT"
      local_ssd_count             = 0
      disk_size_gb                = 100
      disk_type                   = "pd-standard"
      spot                        = false
      boot_disk_kms_key           = ""
      enable_secure_boot          = false
      enable_integrity_monitoring = true
    },
    {
      name             = "state-database"
      machine_type     = "e2-medium"
      image_type       = "COS_CONTAINERD"
      min_cpu_platform = ""
      # or see https://cloud.google.com/compute/docs/instances/specify-min-cpu-platform#availablezones
      autoscaling                 = true
      node_count                  = null # should not be used alongside autoscaling
      max_pods_per_node           = 110
      initial_node_count          = 1
      min_count                   = 1          # per zone. It is null if used alongside total_min_count
      max_count                   = 10         # per zone. It is null if used alongside total_max_count
      total_min_count             = 1          # per NodePool
      total_max_count             = 10         # per NodePool
      location_policy             = "BALANCED" # or ANY
      auto_repair                 = true
      auto_upgrade                = true
      enable_gcfs                 = false
      enable_gvnic                = false
      logging_variant             = "DEFAULT"
      local_ssd_count             = 0
      disk_size_gb                = 100
      disk_type                   = "pd-standard"
      spot                        = false
      boot_disk_kms_key           = ""
      enable_secure_boot          = false
      enable_integrity_monitoring = true
    },
    {
      name             = "others"
      machine_type     = "e2-medium"
      image_type       = "COS_CONTAINERD"
      min_cpu_platform = ""
      # or see https://cloud.google.com/compute/docs/instances/specify-min-cpu-platform#availablezones
      autoscaling                 = true
      node_count                  = null # should not be used alongside autoscaling
      max_pods_per_node           = 110
      initial_node_count          = 0
      min_count                   = 0          # per zone. It is null if used alongside total_min_count
      max_count                   = 100        # per zone. It is null if used alongside total_max_count
      total_min_count             = 0          # per NodePool
      total_max_count             = 100        # per NodePool
      location_policy             = "BALANCED" # or ANY
      auto_repair                 = true
      auto_upgrade                = true
      enable_gcfs                 = false
      enable_gvnic                = false
      logging_variant             = "DEFAULT"
      local_ssd_count             = 0
      disk_size_gb                = 100
      disk_type                   = "pd-standard"
      spot                        = true
      boot_disk_kms_key           = ""
      enable_secure_boot          = false
      enable_integrity_monitoring = true
    }
  ]
}