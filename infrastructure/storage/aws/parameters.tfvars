# Profile
profile = "default"

# Region
region = "eu-west-3"

# TAG
tag = ""

# AWS VPC of EKS
armonik_vpc_id = "vpc-03dd7df68e8caaad9"

# AWS Elasticache
elasticache = {
  engine           = "redis"
  engine_version   = "6.x"
  node_type        = "cache.r4.large"
  kms_key_id       = ""
  vpc              = {
    id          = ""
    cidr_blocks = []
    subnet_ids  = []
  }
  cluster_mode     = {
    replicas_per_node_group = 0
    num_node_groups         = 1 #Valid values are 0 to 5
  }
  multi_az_enabled = false
  tags             = {}
}