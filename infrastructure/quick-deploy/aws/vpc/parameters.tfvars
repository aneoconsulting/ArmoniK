# Profile
profile = "default"

# Region
region = "eu-west-3"

# SUFFIX
suffix = "main"

# AWS TAGs
tags = {
  name             = ""
  env              = ""
  entity           = ""
  bu               = ""
  owner            = ""
  application_code = ""
  project_code     = ""
  cost_center      = ""
  support_contact  = ""
  origin           = ""
  unit_of_measure  = ""
  epic             = ""
  functional_block = ""
  hostname         = ""
  interruptible    = ""
  tostop           = ""
  tostart          = ""
  branch           = ""
  gridserver       = ""
  it_division      = ""
  confidentiality  = ""
  csp              = ""
}

# EKS cluster name
cluster_name  = "armonik-eks"

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
  peering                                         = {
    enabled      = false
    peer_vpc_ids = []
  }
}