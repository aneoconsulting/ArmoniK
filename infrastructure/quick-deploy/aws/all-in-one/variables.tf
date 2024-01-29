# Prefix
variable "prefix" {
  description = "Prefix used to name all the resources"
  type        = string
  default     = null # random
}

# Profile
variable "profile" {
  description = "Profile of AWS credentials to deploy Terraform sources"
  type        = string
  default     = "default"
}

# Kubeconfig file path
variable "kubeconfig_file" {
  description = "Kubeconfig file path"
  type        = string
  default     = "generated/kubeconfig"
}

# Region
variable "region" {
  description = "AWS region where the infrastructure will be deployed"
  type        = string
  default     = "eu-west-3"
}

# Kubernetes namespace
variable "namespace" {
  description = "Kubernetes namespace for ArmoniK"
  type        = string
  default     = "armonik"
}

# Logging level
variable "logging_level" {
  description = "Logging level in ArmoniK"
  type        = string
  default     = "Information"
}

# KMS Key
variable "kms_key" {
  description = "KMS key id used to encrypt logs and storage"
  type        = string
  default     = null
}

# AWS TAGs
variable "tags" {
  description = "Tags for AWS resources"
  type        = map(string)
  default     = {}
}

# VPC
variable "vpc" {
  description = "Parameters of AWS VPC"
  type = object({
    # list of CIDR block associated with the private subnet
    cidr_block_private = optional(list(string), [
      "10.0.0.0/18", "10.0.64.0/18", "10.0.128.0/18"
    ])
    # list of CIDR block associated with the public subnet
    cidr_block_public = optional(list(string), [
      "10.0.192.0/24", "10.0.193.0/24", "10.0.194.0/24"
    ])
    # Main CIDR block associated to the VPC
    main_cidr_block = optional(string, "10.0.0.0/16")
    # cidr block associated with pod
    pod_cidr_block_private = optional(list(string), [
      "10.1.0.0/16", "10.2.0.0/16", "10.3.0.0/16"
    ])
    enable_private_subnet                           = optional(bool, true)
    flow_log_cloudwatch_log_group_retention_in_days = optional(number, 30)
    peering = optional(object({
      enabled      = optional(bool, false)
      peer_vpc_ids = optional(list(string), [])
    }), {})
  })
  default = {}
}

# AWS EKS
variable "eks" {
  description = "Parameters of AWS EKS"
  type = object({
    cluster_version                       = string
    cluster_endpoint_private_access       = optional(bool, true) # vpc.enable_private_subnet
    cluster_endpoint_private_access_cidrs = optional(list(string), [])
    cluster_endpoint_private_access_sg    = optional(list(string), [])
    cluster_endpoint_public_access        = optional(bool, false)
    cluster_endpoint_public_access_cidrs  = optional(list(string), ["0.0.0.0/0"])
    cluster_log_retention_in_days         = optional(number, 30)
    node_selector                         = optional(any, {})
    docker_images = optional(object({
      cluster_autoscaler = optional(object({
        image = optional(string, "registry.k8s.io/autoscaling/cluster-autoscaler")
        tag   = optional(string)
      }), {})
      instance_refresh = optional(object({
        image = optional(string, "public.ecr.aws/aws-ec2/aws-node-termination-handler")
        tag   = optional(string)
      }), {})
    }), {})
    cluster_autoscaler = optional(object({
      expander                              = optional(string, "least-waste")
      scale_down_enabled                    = optional(bool, true)
      min_replica_count                     = optional(number, 0)
      scale_down_utilization_threshold      = optional(number, 0.5)
      scale_down_non_empty_candidates_count = optional(number, 30)
      max_node_provision_time               = optional(string, "15m0s")
      scan_interval                         = optional(string, "10s")
      scale_down_delay_after_add            = optional(string, "2m")
      scale_down_delay_after_delete         = optional(string, "0s")
      scale_down_delay_after_failure        = optional(string, "3m")
      scale_down_unneeded_time              = optional(string, "2m")
      skip_nodes_with_system_pods           = optional(bool, true)
      version                               = optional(string)
      repository                            = optional(string)
      namespace                             = optional(string, "kube-system")
    }), {})
    instance_refresh = optional(object({
      namespace  = optional(string, "kube-system")
      repository = optional(string)
      version    = optional(string)
    }), {})
    map_roles = optional(list(object({
      rolearn  = string
      username = string
      groups   = list(string)
    })), [])
    map_users = optional(list(object({
      userarn  = string
      username = string
      groups   = list(string)
    })), [])
  })
}

# List of EKS managed node groups
variable "eks_managed_node_groups" {
  description = "List of EKS managed node groups"
  type        = any
  default     = null
}

# List of self managed node groups
variable "self_managed_node_groups" {
  description = "List of self managed node groups"
  type        = any
  default     = null
}

# List of fargate profiles
variable "fargate_profiles" {
  description = "List of fargate profiles"
  type        = any
  default     = null
}

# Metrics Server
variable "metrics_server" {
  description = "Parameters of the metrics server"
  type = object({
    namespace          = optional(string, "kube-system"),
    image_name         = optional(string, "registry.k8s.io/metrics-server/metrics-server"),
    image_tag          = optional(string),
    image_pull_secrets = optional(string, ""),
    node_selector      = optional(any, {}),
    args = optional(list(string), [
      "--cert-dir=/tmp",
      "--kubelet-preferred-address-types=InternalIP,ExternalIP,Hostname",
      "--kubelet-use-node-status-port",
      "--metric-resolution=15s",
    ]),
    host_network          = optional(bool, false),
    helm_chart_repository = optional(string)
    helm_chart_version    = optional(string)
  })
  default = {}
}

# Keda
variable "keda" {
  description = "Keda configuration"
  type = object({
    namespace                       = optional(string, "default")
    keda_image_name                 = optional(string, "ghcr.io/kedacore/keda"),
    keda_image_tag                  = optional(string),
    apiserver_image_name            = optional(string, "ghcr.io/kedacore/keda-metrics-apiserver"),
    apiserver_image_tag             = optional(string),
    pull_secrets                    = optional(string, ""),
    node_selector                   = optional(any, {})
    metrics_server_dns_policy       = optional(string, "ClusterFirst")
    metrics_server_use_host_network = optional(bool, false)
    helm_chart_repository           = optional(string)
    helm_chart_version              = optional(string)
  })
  default = {}
}

# S3 as shared storage
variable "s3_fs" {
  description = "AWS S3 bucket as shared storage"
  type = object({
    policy                                = optional(string, "")
    attach_policy                         = optional(bool, false)
    attach_deny_insecure_transport_policy = optional(bool, true)
    attach_require_latest_tls_policy      = optional(bool, true)
    attach_public_policy                  = optional(bool, false)
    block_public_acls                     = optional(bool, true)
    block_public_policy                   = optional(bool, true)
    ignore_public_acls                    = optional(bool, true)
    restrict_public_buckets               = optional(bool, true)
    sse_algorithm                         = optional(string, "")
    ownership                             = optional(string, "BucketOwnerPreferred")
    versioning                            = optional(string, "Disabled")
  })
  default = {}
}


# AWS Elasticache
variable "elasticache" {
  description = "Parameters of Elasticache"
  type = object({
    engine                      = string
    engine_version              = string
    node_type                   = string
    apply_immediately           = optional(bool, true)
    multi_az_enabled            = optional(bool, false)
    automatic_failover_enabled  = optional(bool, true)
    num_cache_clusters          = number
    preferred_cache_cluster_azs = optional(list(string), [])
    data_tiering_enabled        = optional(bool, false)
    log_retention_in_days       = optional(number, 30)
    cloudwatch_log_groups = optional(object({
      slow_log   = optional(string, "")
      engine_log = optional(string, "")
    }), {})
  })
  default = null
}

# S3 as object storage
variable "s3_os" {
  description = "AWS S3 bucket as shared storage"
  type = object({
    policy                                = optional(string, "")
    attach_policy                         = optional(bool, false)
    attach_deny_insecure_transport_policy = optional(bool, true)
    attach_require_latest_tls_policy      = optional(bool, true)
    attach_public_policy                  = optional(bool, false)
    block_public_acls                     = optional(bool, true)
    block_public_policy                   = optional(bool, true)
    ignore_public_acls                    = optional(bool, true)
    restrict_public_buckets               = optional(bool, true)
    sse_algorithm                         = optional(string, "")
    ownership                             = optional(string, "BucketOwnerPreferred")
    versioning                            = optional(string, "Disabled")
  })
  default = null
}

# MQ parameters
variable "mq" {
  description = "MQ Service parameters"
  type = object({
    engine_type             = string
    engine_version          = string
    host_instance_type      = string
    apply_immediately       = optional(bool, true)
    deployment_mode         = optional(string, "SINGLE_INSTANCE")
    storage_type            = optional(string, "ebs")
    authentication_strategy = optional(string, "simple")
    publicly_accessible     = optional(bool, false)
  })
}

# MQ Credentials
variable "mq_credentials" {
  description = "Amazon MQ credentials"
  type = object({
    password = string
    username = string
  })
  default = {
    password = ""
    username = ""
  }
}

# Parameters for MongoDB
variable "mongodb" {
  description = "Parameters of MongoDB"
  type = object({
    image_name      = optional(string, "mongo")
    image_tag       = optional(string)
    node_selector   = optional(any, {})
    pull_secrets    = optional(string, "")
    replicas_number = optional(number, 1)
    persistent_volume = optional(object({
      storage_provisioner = string
      parameters          = optional(map(string), {})
      #Resources for PVC
      resources = optional(object({
        limits = optional(object({
          storage = optional(string)
        }))
        requests = optional(object({
          storage = optional(string)
        }))
      }), {})
    }))
  })
  default = {}
}

# AWS EFS as Persistent volume
variable "pv_efs" {
  description = "AWS EFS as Persistent volume"
  type = object({
    # AWS Elastic Filesystem Service
    efs = optional(object({
      performance_mode                = optional(string, "generalPurpose") # "generalPurpose" or "maxIO"
      throughput_mode                 = optional(string, "bursting")       #  "bursting" or "provisioned"
      provisioned_throughput_in_mibps = optional(number, null)
      transition_to_ia                = optional(string, "AFTER_7_DAYS")
      # "AFTER_7_DAYS", "AFTER_14_DAYS", "AFTER_30_DAYS", "AFTER_60_DAYS", or "AFTER_90_DAYS"
      access_point = optional(list(string), [])
    }), {})
    # EFS Container Storage Interface (CSI) Driver
    csi_driver = optional(object({
      namespace     = optional(string, "kube-system")
      pull_secrets  = optional(string, "")
      node_selector = optional(any, {})
      repository    = optional(string)
      version       = optional(string)
      images = optional(object({
        efs_csi = optional(object({
          name = optional(string, "amazon/aws-efs-csi-driver")
          tag  = optional(string)
        }), {})
        livenessprobe = optional(object({
          name = optional(string, "public.ecr.aws/eks-distro/kubernetes-csi/livenessprobe")
          tag  = optional(string)
        }), {})
        node_driver_registrar = optional(object({
          name = optional(string, "public.ecr.aws/eks-distro/kubernetes-csi/node-driver-registrar")
          tag  = optional(string)
        }), {})
        external_provisioner = optional(object({
          name = optional(string, "public.ecr.aws/eks-distro/kubernetes-csi/external-provisioner")
          tag  = optional(string)
        }), {})
      }), {})
    }), {})
  })
  default = null
}

variable "seq" {
  description = "Seq configuration (nullable)"
  type = object({
    image_name        = optional(string, "datalust/seq")
    image_tag         = optional(string)
    port              = optional(number, 8080)
    pull_secrets      = optional(string, "")
    service_type      = optional(string, "ClusterIP")
    node_selector     = optional(any, {})
    system_ram_target = optional(number, 0.2)
    authentication    = optional(bool, false)
    cli_image_name    = optional(string, "datalust/seqcli")
    cli_image_tag     = optional(string)
    cli_pull_secrets  = optional(string, "")
    retention_in_days = optional(string, "2d")
  })
  default = null
}

variable "grafana" {
  description = "Grafana configuration (nullable)"
  type = object({
    image_name     = optional(string, "grafana/grafana")
    image_tag      = optional(string)
    port           = optional(number, 3000)
    pull_secrets   = optional(string, "")
    service_type   = optional(string, "ClusterIP")
    node_selector  = optional(any, {})
    authentication = optional(bool, false)
  })
  default = null
}

variable "node_exporter" {
  description = "Node exporter configuration (nullable)"
  type = object({
    image_name    = optional(string, "prom/node-exporter")
    image_tag     = optional(string)
    pull_secrets  = optional(string, "")
    service_type  = optional(string, "ClusterIP")
    node_selector = optional(any, {})
  })
  default = null
}

variable "prometheus" {
  description = "Prometheus configuration"
  type = object({
    image_name    = optional(string, "prom/prometheus")
    image_tag     = optional(string)
    pull_secrets  = optional(string, "")
    service_type  = optional(string, "ClusterIP")
    node_selector = optional(any, {})
  })
  default = {}
}

variable "metrics_exporter" {
  description = "Metrics exporter configuration"
  type = object({
    image_name    = optional(string, "dockerhubaneo/armonik_control_metrics")
    image_tag     = optional(string)
    pull_secrets  = optional(string, "")
    service_type  = optional(string, "ClusterIP")
    node_selector = optional(any, {})
    extra_conf    = optional(map(string), {})
  })
  default = {}
}

variable "partition_metrics_exporter" {
  description = "Partition metrics exporter configuration (nullable)"
  type = object({
    image_name    = optional(string, "dockerhubaneo/armonik_control_partition_metrics")
    image_tag     = optional(string)
    pull_secrets  = optional(string, "")
    service_type  = optional(string, "ClusterIP")
    node_selector = optional(any, {})
    extra_conf    = optional(map(string), {})
  })
  default = null
}

variable "fluent_bit" {
  description = "Fluent bit configuration"
  type = object({
    image_name                      = optional(string, "fluent/fluent-bit")
    image_tag                       = optional(string)
    pull_secrets                    = optional(string, "")
    is_daemonset                    = optional(bool, true)
    http_port                       = optional(number, 2020)
    read_from_head                  = optional(bool, true)
    node_selector                   = optional(any, {})
    parser                          = optional(string, "cri")
    fluentbitstate_hostpath         = optional(string, "/var/fluent-bit/state")
    varlibdockercontainers_hostpath = optional(string, "/var/lib/docker/containers")
    runlogjournal_hostpath          = optional(string, "/run/log/journal")
  })
  default = {}
}

variable "cloudwatch" {
  description = "Cloudwatch configuration"
  type = object({
    retention_in_days = optional(number, 30)
  })
  default = {}
}

variable "s3" {
  description = "S3 bucket for logs"
  type = object({
    enabled = optional(bool, true)
    name    = optional(string, "armonik-logs")
    region  = optional(string, "eu-west-3")
    arn     = optional(string, "arn:aws:s3:::armonik-logs")
    prefix  = optional(string, "main")
  })
  default = {}
}

# Extra configuration
variable "extra_conf" {
  description = "Add extra configuration in the configmaps"
  type = object({
    compute = optional(map(string), {})
    control = optional(map(string), {})
    core    = optional(map(string), {})
    log     = optional(map(string), {})
    polling = optional(map(string), {})
    worker  = optional(map(string), {})
  })
  default = {}
}

# Job to insert partitions in the database
variable "job_partitions_in_database" {
  description = "Job to insert partitions IDs in the database"
  type = object({
    name               = optional(string, "job-partitions-in-database")
    image              = optional(string, "rtsp/mongosh")
    tag                = optional(string)
    image_pull_policy  = optional(string, "IfNotPresent")
    image_pull_secrets = optional(string, "")
    node_selector      = optional(any, {})
    annotations        = optional(any, {})
  })
  default = {}
}

# Parameters of control plane
variable "control_plane" {
  description = "Parameters of the control plane"
  type = object({
    name                 = optional(string, "control-plane")
    service_type         = optional(string, "ClusterIP")
    replicas             = optional(number, 2)
    image                = optional(string, "dockerhubaneo/armonik_control")
    tag                  = optional(string)
    image_pull_policy    = optional(string, "IfNotPresent")
    port                 = optional(number, 5001)
    service_account_name = optional(string, "")
    limits = optional(object({
      cpu    = optional(string)
      memory = optional(string)
    }))
    requests = optional(object({
      cpu    = optional(string)
      memory = optional(string)
    }))
    image_pull_secrets = optional(string, "")
    node_selector      = optional(any, {})
    annotations        = optional(any, {})
    # KEDA scaler
    hpa               = optional(any)
    default_partition = string
  })
}

# Parameters of admin gui
variable "admin_gui" {
  description = "Parameters of the admin GUI"
  type = object({
    name  = optional(string, "admin-app")
    image = optional(string, "dockerhubaneo/armonik_admin_app")
    tag   = optional(string)
    port  = optional(number, 1080)
    limits = optional(object({
      cpu    = optional(string)
      memory = optional(string)
    }))
    requests = optional(object({
      cpu    = optional(string)
      memory = optional(string)
    }))
    service_type       = optional(string, "ClusterIP")
    replicas           = optional(number, 1)
    image_pull_policy  = optional(string, "IfNotPresent")
    image_pull_secrets = optional(string, "")
    node_selector      = optional(any, {})
  })
  default = {}
}

# Parameters of the compute plane
variable "compute_plane" {
  description = "Parameters of the compute plane"
  type = map(object({
    replicas                         = optional(number, 1)
    termination_grace_period_seconds = optional(number, 30)
    image_pull_secrets               = optional(string, "IfNotPresent")
    node_selector                    = optional(any, {})
    annotations                      = optional(any, {})
    service_account_name             = optional(string, "")
    polling_agent = optional(object({
      image             = optional(string, "dockerhubaneo/armonik_pollingagent")
      tag               = optional(string)
      image_pull_policy = optional(string, "IfNotPresent")
      limits = optional(object({
        cpu    = optional(string)
        memory = optional(string)
      }))
      requests = optional(object({
        cpu    = optional(string)
        memory = optional(string)
      }))
    }), {})
    worker = list(object({
      name              = optional(string, "worker")
      image             = string
      tag               = optional(string)
      image_pull_policy = optional(string, "IfNotPresent")
      limits = optional(object({
        cpu    = optional(string)
        memory = optional(string)
      }))
      requests = optional(object({
        cpu    = optional(string)
        memory = optional(string)
      }))
    }))
    cache_config = optional(object({
      memory     = optional(bool)
      size_limit = optional(string)
    }), {})
    # KEDA scaler
    hpa = optional(any)
  }))
}

variable "ingress" {
  description = "Parameters of the ingress controller (nullable)"
  type = object({
    name              = optional(string, "ingress")
    service_type      = optional(string, "LoadBalancer")
    replicas          = optional(number, 1)
    image             = optional(string, "nginxinc/nginx-unprivileged")
    tag               = optional(string)
    image_pull_policy = optional(string, "IfNotPresent")
    http_port         = optional(number, 5000)
    grpc_port         = optional(number, 5001)
    limits = optional(object({
      cpu    = optional(string)
      memory = optional(string)
    }))
    requests = optional(object({
      cpu    = optional(string)
      memory = optional(string)
    }))
    image_pull_secrets    = optional(string, "")
    node_selector         = optional(any, {})
    annotations           = optional(any, {})
    tls                   = optional(bool, false)
    mtls                  = optional(bool, false)
    generate_client_cert  = optional(bool, true)
    custom_client_ca_file = optional(string, "")
  })
  default = {}
}

# Authentication behavior
variable "authentication" {
  description = "Authentication behavior"
  type = object({
    name                    = optional(string, "job-authentication-in-database")
    image                   = optional(string, "rtsp/mongosh")
    tag                     = optional(string)
    image_pull_policy       = optional(string, "IfNotPresent")
    image_pull_secrets      = optional(string, "")
    node_selector           = optional(any, {})
    authentication_datafile = optional(string, "")
    require_authentication  = optional(bool, false)
    require_authorization   = optional(bool, false)
  })
  default = {}
}

variable "armonik_versions" {
  description = "Versions of all the ArmoniK components"
  type = object({
    infra     = string
    core      = string
    api       = string
    gui       = string
    extcsharp = string
    samples   = string
  })
}

variable "armonik_images" {
  description = "Image names of all the ArmoniK components"
  type = object({
    infra     = set(string)
    core      = set(string)
    api       = set(string)
    gui       = set(string)
    extcsharp = set(string)
    samples   = set(string)
  })
}

variable "image_tags" {
  description = "Tags of images used"
  type        = map(string)
}

variable "helm_charts" {
  description = "Versions of helm charts repositories"
  type = map(object({
    repository = string
    version    = string
  }))
}

variable "ecr" {
  description = "AWS ECR for docker images"
  type = object({
    encryption_type = optional(string, "KMS")
  })
  default = {}
}

variable "environment_description" {
  description = "Description of the environment"
  type        = any
  default     = null
}

# Extra configuration for jobs connecting to database
variable "jobs_in_database_extra_conf" {
  description = "Add extra configuration in the configmaps for jobs connecting to database"
  type        = map(string)
  default     = {}
}
