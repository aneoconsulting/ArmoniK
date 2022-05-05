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

# Parameters of control plane
control_plane = {
  name               = "control-plane"
  service_type       = "ClusterIP"
  replicas           = 1
  image              = "125796369274.dkr.ecr.eu-west-3.amazonaws.com/armonik-control-plane"
  tag                = "0.5.4"
  image_pull_policy  = "IfNotPresent"
  port               = 5001
  limits             = {
    cpu    = "1000m"
    memory = "1024Mi"
  }
  requests           = {
    cpu    = "100m"
    memory = "128Mi"
  }
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
    # ArmoniK polling agent
    polling_agent                    = {
      image             = "125796369274.dkr.ecr.eu-west-3.amazonaws.com/armonik-polling-agent"
      tag               = "0.5.4"
      image_pull_policy = "IfNotPresent"
      limits            = {
        cpu    = "100m"
        memory = "128Mi"
      }
      requests          = {
        cpu    = "100m"
        memory = "128Mi"
      }
    }
    # ArmoniK workers
    worker                           = [
      {
        name              = "worker"
        port              = 80
        image             = "125796369274.dkr.ecr.eu-west-3.amazonaws.com/armonik-worker"
        tag               = "0.5.2"
        image_pull_policy = "IfNotPresent"
        limits            = {
          cpu    = "920m"
          memory = "2048Mi"
        }
        requests          = {
          cpu    = "50m"
          memory = "100Mi"
        }
      }
    ]
    hpa                              = {
      min_replicas   = 1
      max_replicas   = 100
      object_metrics = [
        {
          described_object = {
            api_version = "batch/v1"
            kind        = "Job"
          }
          metric_name      = "armonik_tasks_queued"
          target           = {
            type                = "AverageValue" # "Value", "Utilization" or "AverageValue"
            average_value       = 2
            average_utilization = 0
            value               = 0
          }
        }
      ]
    }
  }
]

ingress = {
  name               = "ingress"
  service_type       = "LoadBalancer"
  replicas           = 1
  image              = "nginx"
  tag                = "latest"
  image_pull_policy  = "IfNotPresent"
  http_port          = 443
  grpc_port          = 443
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
  tls                = true
  mtls               = true
}
