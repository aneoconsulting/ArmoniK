# Loaded automatically, like registry-credentials.auto.tfvars. All the parameters: variables.tf.
# Helm releases, partitions and NLB access: ../k8s/terraform.tfvars

# Name of every resource (cluster, RDS, bucket, ECR...)
prefix = "armonik69"
region = "eu-west-3"
# AWS CLI profile; null uses the environment credentials
# profile = "my-sso-profile"

tags = {
  "origin" = "terraform"
  "csp"    = "aws"
}

vpc = {
  single_nat_gateway = true
  flow_logs          = false
  # interface_endpoints = ["ecr.api", "ecr.dkr", "sts", "sqs"]
}

eks = {
  kubernetes_version = "1.35"
  # The role running terraform is already admin, and so is everyone using the same SSO permission set
  # admin_principal_arns = ["arn:aws:iam::125796369274:role/AWSReservedSSO_Other-Set_0123456789abcdef"]
}

rds = {
  instance_class = "db.m7g.large"
  multi_az       = false
}
