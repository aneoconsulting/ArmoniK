# Current account
data "aws_caller_identity" "current" {}

# Current AWS region
data "aws_region" "current" {}

locals {
  account_id = data.aws_caller_identity.current.id
  region     = data.aws_region.current.name
  tags       = merge(var.tags, { resource = "MQ Brocker" })
  subnet_ids = (var.mq.deployment_mode == "SINGLE_INSTANCE" ? [var.vpc.subnet_ids[0]] : [
    var.vpc.subnet_ids[0],
    var.vpc.subnet_ids[1]
  ])
  username   = (var.user.username != "" ? var.user.username : random_string.user.result)
  password   = (var.user.password != "" ? var.user.password : random_password.password.result)
}
