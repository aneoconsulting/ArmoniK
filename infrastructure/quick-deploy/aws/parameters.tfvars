# Profile
profile = "default"

# Region
region = "eu-west-3"

# TAG
tag = ""

# List of ECR repositories to create
ecr = {
  kms_key_id   = ""
  repositories = [
    {
      name  = "mongodb"
      image = "mongo"
      tag   = "4.4.11"
    },
    {
      name  = "redis"
      image = "redis"
      tag   = "bullseye"
    },
    {
      name  = "activemq"
      image = "symptoma/activemq"
      tag   = "5.16.3"
    },
    {
      name  = "armonik-control-plane"
      image = "dockerhubaneo/armonik_control"
      tag   = "0.4.0"
    },
    {
      name  = "armonik-polling-agent"
      image = "dockerhubaneo/armonik_pollingagent"
      tag   = "0.4.0"
    },
    {
      name  = "armonik-worker"
      image = "dockerhubaneo/armonik_worker_dll"
      tag   = "0.1.2-SNAPSHOT.4.cfda5d1"
    },
    {
      name  = "seq"
      image = "datalust/seq"
      tag   = "2021.4"
    },
    {
      name  = "grafana"
      image = "grafana/grafana"
      tag   = "latest"
    },
    {
      name  = "prometheus"
      image = "prom/prometheus"
      tag   = "latest"
    },
    {
      name  = "cluster-autoscaler"
      image = "k8s.gcr.io/autoscaling/cluster-autoscaler"
      tag   = "v1.21.0"
    },
    {
      name  = "aws-node-termination-handler"
      image = "amazon/aws-node-termination-handler"
      tag   = "v1.10.0"
    },
    {
      name  = "fluent-bit"
      image = "fluent/fluent-bit"
      tag   = "1.3.11"
    }
  ]
}

# VPC
vpc = {
  name                                            = "armonik-vpc"
  # list of CIDR block associated with the private subnet
  cidr_block_private                              = ["10.0.0.0/18", "10.0.64.0/18", "10.0.128.0/18"]
  # list of CIDR block associated with the public subnet
  cidr_block_public                               = ["10.0.192.0/24", "10.0.193.0/24", "10.0.194.0/24"]
  # Main CIDR block associated to the VPC
  main_cidr_block                                 = "10.0.0.0/16"
  # cidr block associated with pod
  pod_cidr_block_private                          = ["10.1.0.0/16", "10.2.0.0/16", "10.3.0.0/16"]
  enable_private_subnet                           = true
  flow_log_cloudwatch_log_group_kms_key_id        = ""
  flow_log_cloudwatch_log_group_retention_in_days = 30
}

# S3 as shared storage
s3_bucket_fs = {
  name       = "armonik-s3fs"
  kms_key_id = ""
}

# AWS Elasticache
elasticache = {
  name             = "armonik-elasticache"
  engine           = "redis"
  engine_version   = "6.x"
  node_type        = "cache.r4.large"
  kms_key_id       = ""
  vpc              = {
    id          = ""
    cidr_blocks = []
    subnet_ids  = []
  }
  multi_az_enabled = false
  cluster_mode     = {
    replicas_per_node_group = 0
    num_node_groups         = 1 #Valid values are 0 to 5
  }
}

# AWS EKS
eks = {
  name                                 = "armonik-eks"
  cluster_version                      = "1.21"
  vpc_private_subnet_ids               = []
  vpc_id                               = ""
  pods_subnet_ids                      = []
  enable_private_subnet                = true
  cluster_endpoint_public_access       = true
  cluster_endpoint_public_access_cidrs = ["0.0.0.0/0"]
  cluster_log_retention_in_days        = 30
  docker_images                        = {
    cluster_autoscaler = {
      image = "k8s.gcr.io/autoscaling/cluster-autoscaler"
      tag   = "v1.21.0"
    }
    instance_refresh   = {
      image = "amazon/aws-node-termination-handler"
      tag   = "v1.10.0"
    }
  }
  encryption_keys                      = {
    cluster_log_kms_key_id    = ""
    cluster_encryption_config = ""
    ebs_kms_key_id            = ""
  }
  s3_fs                                = {
    name       = ""
    kms_key_id = ""
    host_path  = "/data"
  }
}

# MQ parameters
mq = {
  name               = "armonik-mq"
  engine_type        = "ActiveMQ"
  engine_version     = "5.16.3"
  host_instance_type = "mq.m5.large"
  deployment_mode    = "SINGLE_INSTANCE" #"ACTIVE_STANDBY_MULTI_AZ"
  storage_type       = "efs" #"ebs"
  kms_key_id         = ""
  user               = {
    password = "MindTheGapOfPassword"
    username = "ExampleUser"
  }
  vpc                = {
    id          = ""
    cidr_blocks = []
    subnet_ids  = []
  }
}

# EKS worker groups
eks_worker_groups = [
  {
    name                    = "worker-small-spot"
    override_instance_types = ["m5.xlarge", "m5d.xlarge", "m5a.xlarge"]
    spot_instance_pools     = 0
    asg_min_size            = 0
    asg_max_size            = 20
    asg_desired_capacity    = 0
    on_demand_base_capacity = 0
  },
  {
    name                    = "worker-2xmedium-spot"
    override_instance_types = ["m5.2xlarge", "m5d.2xlarge", "m5a.2xlarge"]
    spot_instance_pools     = 0
    asg_min_size            = 0
    asg_max_size            = 20
    asg_desired_capacity    = 0
    on_demand_base_capacity = 0
  },
  {
    name                    = "worker-4xmedium-spot"
    override_instance_types = ["m5.4xlarge", "m5d.4xlarge", "m5a.4xlarge"]
    spot_instance_pools     = 0
    asg_min_size            = 0
    asg_max_size            = 20
    asg_desired_capacity    = 0
    on_demand_base_capacity = 0
  },
  {
    name                    = "worker-8xmedium-spot"
    override_instance_types = ["m5.8xlarge", "m5d.8xlarge", "m5a.8xlarge"]
    spot_instance_pools     = 0
    asg_min_size            = 0
    asg_max_size            = 20
    asg_desired_capacity    = 0
    on_demand_base_capacity = 0
  }
]
