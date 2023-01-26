# Tags
tags = {
  "name"             = ""
  "env"              = ""
  "entity"           = ""
  "bu"               = ""
  "owner"            = ""
  "application code" = ""
  "project code"     = ""
  "cost center"      = ""
  "Support Contact"  = ""
  "origin"           = "terraform"
  "unit of measure"  = ""
  "epic"             = ""
  "functional block" = ""
  "hostname"         = ""
  "interruptible"    = ""
  "tostop"           = ""
  "tostart"          = ""
  "branch"           = ""
  "gridserver"       = ""
  "it division"      = ""
  "Confidentiality"  = ""
  "csp"              = "aws"
  "grafanaserver"    = ""
  "Terraform"        = "true"
  "DST_Update"       = ""
}


vpc = {
  enable_private_subnet = false
}

# AWS EKS
eks = {
  cluster_version = "1.22"
  cluster_autoscaler = {
    node_selector = { "grid/type" = "Operator" }
  }
  cluster_endpoint_public_access = true
  docker_images = {
    cluster_autoscaler = {
      image = "k8s.gcr.io/autoscaling/cluster-autoscaler"
      tag   = "v1.23.0"
    }
    instance_refresh = {
      image = "public.ecr.aws/aws-ec2/aws-node-termination-handler"
      tag   = "v1.15.0"
    }
  }
}

# Operational node groups for EKS
eks_operational_worker_groups = [
  {
    name                                     = "operational-worker-ondemand"
    spot_allocation_strategy                 = "capacity-optimized"
    override_instance_types                  = ["c5.xlarge"]
    spot_instance_pools                      = 0
    asg_min_size                             = 1
    asg_max_size                             = 5
    asg_desired_capacity                     = 1
    on_demand_base_capacity                  = 1
    on_demand_percentage_above_base_capacity = 100
    kubelet_extra_args                       = "--node-labels=grid/type=Operator --register-with-taints=grid/type=Operator:NoSchedule"
  }
]

# EKS worker groups
eks_worker_groups = [
  {
    name                                     = "worker-c5.4xlarge-spot"
    spot_allocation_strategy                 = "capacity-optimized"
    override_instance_types                  = ["c5.4xlarge"]
    spot_instance_pools                      = 0
    asg_min_size                             = 0
    asg_max_size                             = 1000
    asg_desired_capacity                     = 0
    on_demand_base_capacity                  = 0
    on_demand_percentage_above_base_capacity = 0
  }
]
metrics_server = {
  node_selector = { "grid/type" = "Operator" }
}
keda = {
  node_selector = { "grid/type" = "Operator" }
}
elasticache = {
  engine             = "redis"
  engine_version     = "6.x"
  node_type          = "cache.r4.large"
  num_cache_clusters = 2
}
mq = {
  engine_type        = "ActiveMQ"
  engine_version     = "5.16.4"
  host_instance_type = "mq.m5.xlarge"
}
mongodb = {
  image_name    = "mongo"
  image_tag     = "5.0.9"
  node_selector = { "grid/type" = "Operator" }
  #persistent_volume = {
  #  storage_provisioner = "efs.csi.aws.com"
  #  resources = {
  #    requests = {
  #      storage = "5Gi"
  #    }
  #  }
  #}
}
pv_efs = {
  csi_driver = {
    node_selector = { "grid/type" = "Operator" }
    images = {
      efs_csi = {
        name = "amazon/aws-efs-csi-driver"
        tag  = "v1.4.3"
      }
      livenessprobe = {
        name = "public.ecr.aws/eks-distro/kubernetes-csi/livenessprobe"
        tag  = "v2.2.0-eks-1-18-13"
      }
      node_driver_registrar = {
        name = "public.ecr.aws/eks-distro/kubernetes-csi/node-driver-registrar"
        tag  = "v2.1.0-eks-1-18-13"
      }
      external_provisioner = {
        name = "public.ecr.aws/eks-distro/kubernetes-csi/external-provisioner"
        tag  = "v2.1.1-eks-1-18-13"
      }
    }
  }
}

seq = {
  image_name    = "datalust/seq"
  image_tag     = "2022.1"
  node_selector = { "grid/type" = "Operator" }
}

grafana = {
  image_name    = "grafana/grafana"
  image_tag     = "9.2.1"
  node_selector = { "grid/type" = "Operator" }
}

node_exporter = {
  image_name    = "prom/node-exporter"
  image_tag     = "v1.3.1"
  node_selector = { "grid/type" = "Operator" }
}

prometheus = {
  image_name    = "prom/prometheus"
  image_tag     = "v2.36.1"
  node_selector = { "grid/type" = "Operator" }
}

metrics_exporter = {
  image_name    = "dockerhubaneo/armonik_control_metrics"
  image_tag     = "0.8.3"
  node_selector = { "grid/type" = "Operator" }
  extra_conf = {
    MongoDB__AllowInsecureTls           = true
    Serilog__MinimumLevel               = "Information"
    MongoDB__TableStorage__PollingDelay = "00:00:01"
  }
}

/*parition_metrics_exporter = {
  image_name    = "dockerhubaneo/armonik_control_partition_metrics"
  image_tag     = "0.8.3"
  node_selector = { "grid/type" = "Operator" }
  extra_conf    = {
    MongoDB__AllowInsecureTls           = true
    Serilog__MinimumLevel               = "Information"
    MongoDB__TableStorage__PollingDelay = "00:00:01"
  }
}*/

fluent_bit = {
  image_name   = "fluent/fluent-bit"
  image_tag    = "1.9.9"
  is_daemonset = true
}


# Logging level
logging_level = "Information"


# Job to insert partitions in the database
job_partitions_in_database = {
  image = "rtsp/mongosh"
  tag   = "1.5.4"
}

# Parameters of control plane
control_plane = {
  image = "dockerhubaneo/armonik_control"
  tag   = "0.8.3"
  limits = {
    cpu    = "1000m"
    memory = "2048Mi"
  }
  requests = {
    cpu    = "200m"
    memory = "500Mi"
  }
  default_partition = "default"
}

# Parameters of admin GUI
admin_gui = {
  api = {
    image = "dockerhubaneo/armonik_admin_api"
    tag   = "0.7.2"
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
    image = "dockerhubaneo/armonik_admin_app"
    tag   = "0.7.2"
    limits = {
      cpu    = "1000m"
      memory = "1024Mi"
    }
    requests = {
      cpu    = "100m"
      memory = "128Mi"
    }
  }
}

# Parameters of the compute plane
compute_plane = {
  default = {
    # number of replicas for each deployment of compute plane
    replicas = 1
    # ArmoniK polling agent
    polling_agent = {
      image = "dockerhubaneo/armonik_pollingagent"
      tag   = "0.8.3"
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
        image = "dockerhubaneo/armonik_worker_dll"
        tag   = "0.8.2"
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
  image                = "nginxinc/nginx-unprivileged"
  tag                  = "1.23.2"
  tls                  = false
  mtls                 = false
  generate_client_cert = false
}

authentication = {
  image = "rtsp/mongosh"
  tag   = "1.5.4"
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
}
