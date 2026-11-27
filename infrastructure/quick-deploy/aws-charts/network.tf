# ArmoniK.Infra modules from the branch dw/aws-charts-modules until it is released (local_override.tf, git-ignored,
# may point them to a local working copy)

module "vpc" {
  source = "git::https://github.com/aneoconsulting/ArmoniK.Infra.git//networking/aws/vpc?ref=dw/aws-charts-modules"

  name   = local.name
  region = var.region
  cidr   = var.vpc.cidr
  # Three /18 for the nodes and the pods (Cilium ENI mode: VPC IPs), three /24 for the load balancers and the NAT gateway (one)
  private_subnets = [for i in range(3) : cidrsubnet(var.vpc.cidr, 2, i)]
  public_subnets  = [for i in range(3) : cidrsubnet(var.vpc.cidr, 8, 192 + i)]

  # Load balancer role tags, and karpenter.sh/discovery on the private subnets, where Karpenter starts its nodes
  eks_name      = local.name
  use_karpenter = true

  enable_flow_logs                                = var.vpc.flow_logs
  flow_log_cloudwatch_log_group_kms_key_id        = module.kms.key_arn
  flow_log_cloudwatch_log_group_retention_in_days = 7

  tags = local.tags
}

# Free, and keeps the object storage traffic off the NAT gateway
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = module.vpc.id
  service_name      = "com.amazonaws.${var.region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = module.vpc.this.private_route_table_ids
}

# Same for the S3 Express One Zone directory bucket, on its own service
resource "aws_vpc_endpoint" "s3express" {
  count             = var.object_storage.express ? 1 : 0
  vpc_id            = module.vpc.id
  service_name      = "com.amazonaws.${var.region}.s3express"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = module.vpc.this.private_route_table_ids
  tags              = local.tags
}
