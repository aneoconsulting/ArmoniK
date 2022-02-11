# Current account
data "aws_caller_identity" "current" {}

# Current AWS region
data "aws_region" "current" {}

locals {
  account_id = data.aws_caller_identity.current.id
  region     = data.aws_region.current.name
  tags       = merge(var.tags, { resource = "MQ Brocker" })
  subnet_ids = (var.mq.deployment_mode == "SINGLE_INSTANCE" ? [var.mq.vpc.subnet_ids[0]] : [
    var.mq.vpc.subnet_ids[0],
    var.mq.vpc.subnet_ids[1]
  ])
}
