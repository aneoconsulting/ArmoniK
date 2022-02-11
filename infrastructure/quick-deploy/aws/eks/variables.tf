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

# VPC infos
variable "vpc" {
  description = "AWS VPC info"
  type        = object({
    id                     = string
    cidr_block             = string
    private_subnet_ids     = list(string)
    pod_cidr_block_private = list(string)
    pods_subnet_ids        = list(string)
  })
  default     = {
    id                     = ""
    cidr_block             = ""
    private_subnet_ids     = []
    pod_cidr_block_private = []
    pods_subnet_ids        = []
  }
}

# shared storage
variable "s3_fs" {
  description = "S3 bucket as shared storage"
  type        = object({
    name       = string
    kms_key_id = string
    host_path  = string
  })
  default     = {
    name       = ""
    kms_key_id = ""
    host_path  = "/data"
  }
}

# AWS EKS
variable "eks" {
  description = "Parameters of AWS EKS"
  type        = object({
    name                                 = string
    cluster_version                      = string
    cluster_endpoint_private_access      = bool # vpc.enable_private_subnet
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
  })
  default     = {
    name                                 = "armonik-eks"
    cluster_version                      = "1.21"
    cluster_endpoint_private_access      = true # vpc.enable_private_subnet
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
  }
}

# EKS worker groups
variable "eks_worker_groups" {
  description = "List of EKS worker node groups"
  type        = any
  default     = [
    {
      name                                     = "worker-small-spot"
      spot_allocation_strategy                 = "capacity-optimized"
      override_instance_types                  = ["m5.xlarge", "m5d.xlarge", "m5a.xlarge"]
      spot_instance_pools                      = 0
      asg_min_size                             = 0
      asg_max_size                             = 20
      asg_desired_capacity                     = 0
      on_demand_base_capacity                  = 0
      on_demand_percentage_above_base_capacity = 0
      tags                                     = []
    },
    {
      name                                     = "worker-2xmedium-spot"
      spot_allocation_strategy                 = "capacity-optimized"
      override_instance_types                  = ["m5.2xlarge", "m5d.2xlarge", "m5a.2xlarge"]
      spot_instance_pools                      = 0
      asg_min_size                             = 0
      asg_max_size                             = 20
      asg_desired_capacity                     = 0
      on_demand_base_capacity                  = 0
      on_demand_percentage_above_base_capacity = 0
      tags                                     = []
    },
    {
      name                                     = "worker-4xmedium-spot"
      spot_allocation_strategy                 = "capacity-optimized"
      override_instance_types                  = ["m5.4xlarge", "m5d.4xlarge", "m5a.4xlarge"]
      spot_instance_pools                      = 0
      asg_min_size                             = 0
      asg_max_size                             = 20
      asg_desired_capacity                     = 0
      on_demand_base_capacity                  = 0
      on_demand_percentage_above_base_capacity = 0
      tags                                     = []
    },
    {
      name                                     = "worker-8xmedium-spot"
      spot_allocation_strategy                 = "capacity-optimized"
      override_instance_types                  = ["m5.8xlarge", "m5d.8xlarge", "m5a.8xlarge"]
      spot_instance_pools                      = 0
      asg_min_size                             = 0
      asg_max_size                             = 20
      asg_desired_capacity                     = 0
      on_demand_base_capacity                  = 0
      on_demand_percentage_above_base_capacity = 0
      tags                                     = []
    },
    {
      name                                     = "worker-small-ondemand"
      spot_allocation_strategy                 = "capacity-optimized"
      override_instance_types                  = ["m5.xlarge", "m5d.xlarge", "m5a.xlarge"]
      spot_instance_pools                      = 0
      asg_min_size                             = 0
      asg_max_size                             = 20
      asg_desired_capacity                     = 0
      on_demand_base_capacity                  = 0
      on_demand_percentage_above_base_capacity = 100
      kubelet_extra_args                       = "--node-labels=lifecycle=OnDemand"
    }
  ]
}