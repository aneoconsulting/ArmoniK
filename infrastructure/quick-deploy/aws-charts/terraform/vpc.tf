module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 6.7"

  name = local.name
  cidr = var.vpc.cidr
  azs  = local.azs

  # Three /18 for the nodes and the pods (VPC CNI), three /24 for the load balancers and the NAT
  private_subnets = [for i in range(3) : cidrsubnet(var.vpc.cidr, 2, i)]
  public_subnets  = [for i in range(3) : cidrsubnet(var.vpc.cidr, 8, 192 + i)]

  enable_nat_gateway   = true
  single_nat_gateway   = var.vpc.single_nat_gateway
  enable_dns_hostnames = true
  enable_dns_support   = true

  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }
  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
    "karpenter.sh/discovery"          = local.name
  }

  enable_flow_log                                 = var.vpc.flow_logs
  create_flow_log_cloudwatch_log_group            = var.vpc.flow_logs
  create_flow_log_cloudwatch_iam_role             = var.vpc.flow_logs
  flow_log_cloudwatch_log_group_kms_key_id        = var.vpc.flow_logs ? module.kms.key_arn : null
  flow_log_cloudwatch_log_group_retention_in_days = 7
}

module "vpc_endpoints" {
  source  = "terraform-aws-modules/vpc/aws//modules/vpc-endpoints"
  version = "~> 6.7"

  vpc_id = module.vpc.vpc_id

  create_security_group      = length(var.vpc.interface_endpoints) > 0
  security_group_name_prefix = "${local.name}-vpc-endpoints-"
  security_group_rules = {
    ingress_https = {
      cidr_blocks = [module.vpc.vpc_cidr_block]
    }
  }

  endpoints = merge({
    # Free, and keeps the object storage traffic off the NAT gateway
    s3 = {
      service         = "s3"
      service_type    = "Gateway"
      route_table_ids = module.vpc.private_route_table_ids
    }
    }, {
    for service in var.vpc.interface_endpoints : replace(service, ".", "_") => {
      service             = service
      private_dns_enabled = true
      subnet_ids          = module.vpc.private_subnets
    }
  })
}
