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

# Job to insert partitions in the database
job_partitions_in_database = {
  name               = "job-partitions-in-database"
  image              = "125796369274.dkr.ecr.eu-west-3.amazonaws.com/mongosh"
  tag                = "1.7.1"
  image_pull_policy  = "IfNotPresent"
  image_pull_secrets = ""
  node_selector      = { service = "control-plane" }
  annotations        = {}
}

# Parameters of control plane
control_plane = {
  name              = "control-plane"
  service_type      = "ClusterIP"
  replicas          = 1
  image             = "125796369274.dkr.ecr.eu-west-3.amazonaws.com/armonik-control-plane"
  tag               = "0.15.0"
  image_pull_policy = "IfNotPresent"
  port              = 5001
  limits = {
    cpu    = "1000m"
    memory = "2048Mi"
  }
  requests = {
    cpu    = "200m"
    memory = "500Mi"
  }
  image_pull_secrets = ""
  node_selector      = { service = "control-plane" }
  annotations        = {}
  hpa = {
    polling_interval  = 15
    cooldown_period   = 300
    min_replica_count = 3
    max_replica_count = 3
    behavior = {
      restore_to_original_replica_count = true
      stabilization_window_seconds      = 300
      type                              = "Percent"
      value                             = 100
      period_seconds                    = 15
    }
    triggers = [
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
  default_partition = "default"
}

# Parameters of admin GUI
# Put to null if we not want deploy it
admin_gui = {
  name  = "admin-app"
  image = "125796369274.dkr.ecr.eu-west-3.amazonaws.com/armonik-admin-app"
  tag   = "0.9.4"
  port  = 1080
  limits = {
    cpu    = "1000m"
    memory = "1024Mi"
  }
  requests = {
    cpu    = "100m"
    memory = "128Mi"
  }
  service_type       = "ClusterIP"
  replicas           = 1
  image_pull_policy  = "IfNotPresent"
  image_pull_secrets = ""
  node_selector      = { service = "control-plane" }
}

admin_0_9_gui = {
  name  = "admin-0-9-app"
  image = "125796369274.dkr.ecr.eu-west-3.amazonaws.com/armonik-admin-app-0-9"
  tag   = "0.9.5"
  port  = 1080
  limits = {
    cpu    = "1000m"
    memory = "1024Mi"
  }
  requests = {
    cpu    = "100m"
    memory = "128Mi"
  }
  service_type       = "ClusterIP"
  replicas           = 1
  image_pull_policy  = "IfNotPresent"
  image_pull_secrets = ""
  node_selector      = { service = "control-plane" }
}

#Parameters of old admin GUI
admin_0_8_gui = {
  api = {
    name  = "admin-api"
    image = "125796369274.dkr.ecr.eu-west-3.amazonaws.com/armonik-admin-api-0-8"
    tag   = "0.8.1"
    port  = 3333
    limits = {
      cpu    = "1000m"
      memory = "1024Mi"
    }
    requests = {
      cpu    = "100m"
      memory = "128Mi"
    }
  }
  app = {
    name  = "admin-0-8-gui"
    image = "125796369274.dkr.ecr.eu-west-3.amazonaws.com/armonik-admin-app-0-8"
    tag   = "0.8.1"
    port  = 1080
    limits = {
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
  node_selector      = { service = "control-plane" }
}

# Parameters of the compute plane
compute_plane = {
  default = {
    # number of replicas for each deployment of compute plane
    replicas                         = 1
    termination_grace_period_seconds = 30
    image_pull_secrets               = ""
    node_selector                    = { service = "workers" }
    annotations                      = {}
    # ArmoniK polling agent
    polling_agent = {
      image             = "125796369274.dkr.ecr.eu-west-3.amazonaws.com/armonik-polling-agent"
      tag               = "0.15.0"
      image_pull_policy = "IfNotPresent"
      limits = {
        cpu    = "2000m"
        memory = "2048Mi"
      }
      requests = {
        cpu    = "1000m"
        memory = "256Mi"
      }
    }
    # ArmoniK workers
    worker = [
      {
        name              = "worker"
        image             = "125796369274.dkr.ecr.eu-west-3.amazonaws.com/armonik-worker"
        tag               = "0.12.2"
        image_pull_policy = "IfNotPresent"
        limits = {
          cpu    = "1000m"
          memory = "1024Mi"
        }
        requests = {
          cpu    = "500m"
          memory = "512Mi"
        }
      }
    ]
    hpa = {
      type              = "prometheus"
      polling_interval  = 15
      cooldown_period   = 300
      min_replica_count = 1
      max_replica_count = 100
      behavior = {
        restore_to_original_replica_count = true
        stabilization_window_seconds      = 300
        type                              = "Percent"
        value                             = 100
        period_seconds                    = 15
      }
      triggers = [
        {
          type      = "prometheus"
          threshold = 2
        },
      ]
    }
  },
}

# Deploy ingress
# PS: to not deploy ingress put: "ingress=null"
ingress = {
  name                  = "ingress"
  service_type          = "LoadBalancer"
  replicas              = 1
  image                 = "125796369274.dkr.ecr.eu-west-3.amazonaws.com/nginx"
  tag                   = "1.25.1-alpine-slim"
  image_pull_policy     = "IfNotPresent"
  http_port             = 5000
  grpc_port             = 5001
  limits                = null
  requests              = null
  image_pull_secrets    = ""
  node_selector         = { service = "control-plane" }
  annotations           = {}
  tls                   = false
  mtls                  = false
  generate_client_cert  = false
  custom_client_ca_file = ""
}

authentication = {
  name                    = "job-authentication-in-database"
  image                   = "125796369274.dkr.ecr.eu-west-3.amazonaws.com/mongosh"
  tag                     = "1.10.1"
  image_pull_policy       = "IfNotPresent"
  image_pull_secrets      = ""
  node_selector           = { service = "control-plane" }
  authentication_datafile = ""
  require_authentication  = false
  require_authorization   = false
}

extra_conf = {
  core = {
    Amqp__AllowHostMismatch                    = false
    Amqp__MaxPriority                          = "10"
    Amqp__MaxRetries                           = "5"
    Amqp__QueueStorage__LockRefreshPeriodicity = "00:00:45"
    Amqp__QueueStorage__PollPeriodicity        = "00:00:10"
    Amqp__QueueStorage__LockRefreshExtension   = "00:02:00"
    MongoDB__TableStorage__PollingDelayMin     = "00:00:01"
    MongoDB__TableStorage__PollingDelayMax     = "00:00:10"
    MongoDB__TableStorage__PollingDelay        = "00:00:01"
    MongoDB__DataRetention                     = "10.00:00:00"
    MongoDB__AllowInsecureTls                  = true
    Redis__Timeout                             = 3000
    Redis__SslHost                             = ""
  }
  control = {
    Submitter__MaxErrorAllowed = 50
  }
}

environment_description = {
  name        = "aws-dev"
  version     = "0.0.0"
  description = "AWS environment"
  color       = "#80ff80"
}
