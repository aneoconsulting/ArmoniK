# Profile
profile = "default"

# Region
region = "eu-west-3"

# Kubeconfig path
k8s_config_path = "~/.kube/config"

# Kubeconfig context
k8s_config_context = "default"

# Kubernetes namespace
namespace = "armonik"

# Logging level
logging_level = "Information"

# Polling delay to MongoDB
# according to the size of the task and/or the application
mongodb_polling_delay = {
  min_polling_delay = "00:00:01"
  max_polling_delay = "00:00:10"
}

# Parameters of control plane
control_plane = {
  name               = "control-plane"
  service_type       = "ClusterIP"
  replicas           = 1
  image              = "125796369274.dkr.ecr.eu-west-3.amazonaws.com/armonik-control-plane"
  tag                = "0.5.16"
  image_pull_policy  = "IfNotPresent"
  port               = 5001
  limits             = {
    cpu    = "1000m"
    memory = "2048Mi"
  }
  requests           = {
    cpu    = "200m"
    memory = "500Mi"
  }
  image_pull_secrets = ""
  node_selector      = {}
  annotations        = {}
  hpa                = {
    polling_interval  = 15
    cooldown_period   = 300
    min_replica_count = 1
    max_replica_count = 100
    behavior          = {
      restore_to_original_replica_count = true
      stabilization_window_seconds      = 300
      type                              = "Percent"
      value                             = 100
      period_seconds                    = 15
    }
    triggers          = [
      {
        type        = "cpu"
        metric_type = "Utilization"
        value       = "80"
      },
      {
        type        = "memory"
        metric_type = "Utilization"
        value       = "80"
      },
    ]
  }
}

# Parameters of admin GUI
admin_gui = {
  api                = {
    name     = "admin-api"
    replicas = 1
    image    = "125796369274.dkr.ecr.eu-west-3.amazonaws.com/armonik-admin-api"
    tag      = "0.5.1"
    port     = 3333
    limits   = {
      cpu    = "1000m"
      memory = "1024Mi"
    }
    requests = {
      cpu    = "100m"
      memory = "128Mi"
    }
  }
  app                = {
    name     = "admin-app"
    replicas = 1
    image    = "125796369274.dkr.ecr.eu-west-3.amazonaws.com/armonik-admin-app"
    tag      = "0.5.1"
    port     = 1080
    limits   = {
      cpu    = "1000m"
      memory = "1024Mi"
    }
    requests = {
      cpu    = "100m"
      memory = "128Mi"
    }
  }
  service_type       = "ClusterIP"
  replicas           = 1
  image_pull_policy  = "IfNotPresent"
  image_pull_secrets = ""
  node_selector      = {}
}

# Parameters of the compute plane
compute_plane = [
  {
    name                             = "compute-plane"
    # number of replicas for each deployment of compute plane
    replicas                         = 1
    termination_grace_period_seconds = 30
    image_pull_secrets               = ""
    node_selector                    = {}
    annotations                      = {}
    # ArmoniK polling agent
    polling_agent                    = {
      image             = "125796369274.dkr.ecr.eu-west-3.amazonaws.com/armonik-polling-agent"
      tag               = "0.5.16"
      image_pull_policy = "IfNotPresent"
      limits            = {
        cpu    = "2000m"
        memory = "2048Mi"
      }
      requests          = {
        cpu    = "1000m"
        memory = "256Mi"
      }
    }
    # ArmoniK workers
    worker                           = [
      {
        name              = "worker"
        image             = "125796369274.dkr.ecr.eu-west-3.amazonaws.com/armonik-worker"
        tag               = "0.6.5"
        image_pull_policy = "IfNotPresent"
        limits            = {
          cpu    = "1000m"
          memory = "1024Mi"
        }
        requests          = {
          cpu    = "500m"
          memory = "512Mi"
        }
      }
    ]
    hpa                              = {
      type              = "prometheus"
      polling_interval  = 15
      cooldown_period   = 300
      min_replica_count = 1
      max_replica_count = 100
      behavior          = {
        restore_to_original_replica_count = true
        stabilization_window_seconds      = 300
        type                              = "Percent"
        value                             = 100
        period_seconds                    = 15
      }
      triggers          = [
        {
          type        = "prometheus"
          metric_name = "armonik_tasks_queued"
          threshold   = "2"
        },
      ]
    }
  }
]

# Deploy ingress
# PS: to not deploy ingress put: "ingress=null"
ingress = {
  name               = "ingress"
  service_type       = "LoadBalancer"
  replicas           = 1
  image              = "125796369274.dkr.ecr.eu-west-3.amazonaws.com/nginx"
  tag                = "1.23.0"
  image_pull_policy  = "IfNotPresent"
  http_port          = 5000
  grpc_port          = 5001
  limits             = {
    cpu    = "200m"
    memory = "100Mi"
  }
  requests           = {
    cpu    = "1m"
    memory = "1Mi"
  }
  image_pull_secrets = ""
  node_selector      = {}
  annotations        = {}
  tls                = false
  mtls               = false
}
