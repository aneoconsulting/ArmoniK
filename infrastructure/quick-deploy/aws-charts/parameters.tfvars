# prefix (and region, eu-west-3 by default) are passed with -var, and registry_credentials in
# registry-credentials.tfvars: see README.md.

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
