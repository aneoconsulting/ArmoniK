# Profile
variable "profile" {
  description = "Profile of AWS credentials to deploy Terraform sources"
  type        = string
  default     = "default"
}

# Region
variable "region" {
  description = "AWS region where the infrastructure will be deployed"
  type        = string
  default     = "eu-west-3"
}

# TAG
variable "tag" {
  description = "Tag to prefix the AWS resources"
  type        = string
  default     = ""
}

# List of ECR repositories to create
variable "ecr" {
  description = "List of ECR repositories to create"
  type        = object({
    kms_key_id   = string
    repositories = list(any)
  })
  default     = {
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
}

# VPC
variable "vpc" {
  description = "Parameters of AWS VPC"
  type        = object({
    name                                            = string
    # list of CIDR block associated with the private subnet
    cidr_block_private                              = list(string)
    # list of CIDR block associated with the public subnet
    cidr_block_public                               = list(string)
    # Main CIDR block associated to the VPC
    main_cidr_block                                 = string
    # cidr block associated with pod
    pod_cidr_block_private                          = list(string)
    enable_private_subnet                           = bool
    flow_log_cloudwatch_log_group_kms_key_id        = string
    flow_log_cloudwatch_log_group_retention_in_days = number
  })
  default     = {
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
}

# S3 as shared storage
variable "s3_bucket_fs" {
  description = "AWS S3 bucket as shared storage"
  type        = object({
    name       = string
    kms_key_id = string
  })
  default     = {
    name       = "armonik-s3fs"
    kms_key_id = ""
  }
}

# AWS Elasticache
variable "elasticache" {
  description = "Parameters of Elasticache"
  type        = object({
    name             = string
    engine           = string
    engine_version   = string
    node_type        = string
    kms_key_id       = string
    multi_az_enabled = bool
    vpc              = object({
      id          = string
      cidr_blocks = list(string)
      subnet_ids  = list(string)
    })
    cluster_mode     = object({
      replicas_per_node_group = number
      num_node_groups         = number
    })
  })
  default     = {
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
}

# MQ parameters
variable "mq" {
  description = "MQ Service parameters"
  type        = object({
    name               = string
    engine_type        = string
    engine_version     = string
    host_instance_type = string
    deployment_mode    = string
    storage_type       = string
    kms_key_id         = string
    user               = object({
      password = string
      username = string
    })
    vpc                = object({
      id          = string
      cidr_blocks = list(string)
      subnet_ids  = list(string)
    })
  })
  default     = {
    name               = "armonik-mq"
    engine_type        = "ActiveMQ"
    engine_version     = "5.16.3"
    host_instance_type = "mq.m5.large"
    deployment_mode    = "ACTIVE_STANDBY_MULTI_AZ" #"SINGLE_INSTANCE"
    storage_type       = "efs" #"ebs"
    kms_key_id         = ""
    user               = {
      password = ""
      username = ""
    }
    vpc                = {
      id          = ""
      cidr_blocks = []
      subnet_ids  = []
    }
  }
}

# AWS EKS
variable "eks" {
  description = "Parameters of AWS EKS"
  type        = object({
    name                                 = string
    cluster_version                      = string
    vpc_private_subnet_ids               = list(string)
    vpc_id                               = string
    pods_subnet_ids                      = list(string)
    enable_private_subnet                = bool
    cluster_endpoint_public_access       = bool
    cluster_endpoint_public_access_cidrs = list(string)
    cluster_log_retention_in_days        = number
    docker_images                        = object({
      cluster_autoscaler = object({
        image = string
        tag   = string
      })
      instance_refresh   = object({
        image = string
        tag   = string
      })
    })
    encryption_keys                      = object({
      cluster_log_kms_key_id    = string
      cluster_encryption_config = string
      ebs_kms_key_id            = string
    })
    s3_fs                                = object({
      name       = string
      kms_key_id = string
      host_path  = string
    })
  })
  default     = {
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
}

# EKS worker groups
variable "eks_worker_groups" {
  description = "List of EKS worker node groups"
  type        = any
  default     = [
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
}