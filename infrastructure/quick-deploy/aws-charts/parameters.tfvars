# region, profile and prefix come from the Makefile (REGION, PROFILE, PREFIX), and
# registry_credentials from the DOCKER_HUB_* and GITHUB_* environment variables.

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
  # admin_principal_arns = ["arn:aws:iam::123456789012:role/Admin"]
}

rds = {
  instance_class = "db.m7g.large"
  multi_az       = false
}
