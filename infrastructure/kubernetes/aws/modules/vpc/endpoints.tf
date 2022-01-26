module "vpc_endpoints" {
  source             = "terraform-aws-modules/vpc/aws//modules/vpc-endpoints"
  version            = "3.11.1"
  vpc_id             = module.vpc.vpc_id
  security_group_ids = [module.vpc.default_security_group_id]
  create             = true
  depends_on         = [
    module.vpc
  ]

  endpoints = {
    sqs                  = {
      service             = "sqs"
      private_dns_enabled = var.vpc.enable_private_subnet
      subnet_ids          = var.vpc.enable_private_subnet == true ? matchkeys(module.vpc.private_subnets, tolist(module.vpc.private_subnets_cidr_blocks), var.vpc.private_subnets) : []
      security_group_ids  = var.vpc.enable_private_subnet == true ? [module.vpc.default_security_group_id] : []
    }
    s3                   = {
      service         = "s3"
      service_type    = "Gateway"
      route_table_ids = flatten([
        module.vpc.intra_route_table_ids, module.vpc.private_route_table_ids, module.vpc.public_route_table_ids
      ])
    }
    dynamodb             = {
      service         = "dynamodb"
      service_type    = "Gateway"
      route_table_ids = flatten([
        module.vpc.intra_route_table_ids, module.vpc.private_route_table_ids, module.vpc.public_route_table_ids
      ])
    }
    ec2_autoscaling      = {
      service             = "autoscaling"
      private_dns_enabled = var.vpc.enable_private_subnet
      subnet_ids          = var.vpc.enable_private_subnet == true ? matchkeys(module.vpc.private_subnets, tolist(module.vpc.private_subnets_cidr_blocks), var.vpc.private_subnets) : []
      security_group_ids  = var.vpc.enable_private_subnet == true ? [module.vpc.default_security_group_id] : []
    }
    ec2                  = {
      service             = "ec2"
      private_dns_enabled = var.vpc.enable_private_subnet
      subnet_ids          = var.vpc.enable_private_subnet == true ? matchkeys(module.vpc.private_subnets, tolist(module.vpc.private_subnets_cidr_blocks), var.vpc.private_subnets) : []
      security_group_ids  = var.vpc.enable_private_subnet == true ? [module.vpc.default_security_group_id] : []
    }
    ecr_dkr              = {
      service             = "ecr.dkr"
      private_dns_enabled = var.vpc.enable_private_subnet
      subnet_ids          = var.vpc.enable_private_subnet == true ? matchkeys(module.vpc.private_subnets, tolist(module.vpc.private_subnets_cidr_blocks), var.vpc.private_subnets) : []
      security_group_ids  = var.vpc.enable_private_subnet == true ? [module.vpc.default_security_group_id] : []
    }
    ecr_api              = {
      service             = "ecr.api"
      private_dns_enabled = var.vpc.enable_private_subnet
      subnet_ids          = var.vpc.enable_private_subnet == true ? matchkeys(module.vpc.private_subnets, tolist(module.vpc.private_subnets_cidr_blocks), var.vpc.private_subnets) : []
      security_group_ids  = var.vpc.enable_private_subnet == true ? [module.vpc.default_security_group_id] : []
    }
    monitoring           = {
      service             = "monitoring"
      private_dns_enabled = var.vpc.enable_private_subnet
      subnet_ids          = var.vpc.enable_private_subnet == true ? matchkeys(module.vpc.private_subnets, tolist(module.vpc.private_subnets_cidr_blocks), var.vpc.private_subnets) : []
      security_group_ids  = var.vpc.enable_private_subnet == true ? [module.vpc.default_security_group_id] : []
    }
    logs                 = {
      service             = "logs"
      private_dns_enabled = var.vpc.enable_private_subnet
      subnet_ids          = var.vpc.enable_private_subnet == true ? matchkeys(module.vpc.private_subnets, tolist(module.vpc.private_subnets_cidr_blocks), var.vpc.private_subnets) : []
      security_group_ids  = var.vpc.enable_private_subnet == true ? [module.vpc.default_security_group_id] : []
    }
    elasticloadbalancing = {
      service             = "elasticloadbalancing"
      private_dns_enabled = var.vpc.enable_private_subnet
      subnet_ids          = var.vpc.enable_private_subnet == true ? matchkeys(module.vpc.private_subnets, tolist(module.vpc.private_subnets_cidr_blocks), var.vpc.private_subnets) : []
      security_group_ids  = var.vpc.enable_private_subnet == true ? [module.vpc.default_security_group_id] : []
    }
    api_gateway          = {
      service             = "execute-api"
      private_dns_enabled = var.vpc.enable_private_subnet
      subnet_ids          = var.vpc.enable_private_subnet == true ? matchkeys(module.vpc.private_subnets, tolist(module.vpc.private_subnets_cidr_blocks), var.vpc.private_subnets) : []
      security_group_ids  = var.vpc.enable_private_subnet == true ? [module.vpc.default_security_group_id] : []
    }
    ssm                  = {
      service             = "ssm"
      private_dns_enabled = var.vpc.enable_private_subnet
      subnet_ids          = var.vpc.enable_private_subnet == true ? matchkeys(module.vpc.private_subnets, tolist(module.vpc.private_subnets_cidr_blocks), var.vpc.private_subnets) : []
      security_group_ids  = var.vpc.enable_private_subnet == true ? [module.vpc.default_security_group_id] : []
    }
    ssmmessages          = {
      service             = "ssmmessages"
      private_dns_enabled = var.vpc.enable_private_subnet
      subnet_ids          = var.vpc.enable_private_subnet == true ? matchkeys(module.vpc.private_subnets, tolist(module.vpc.private_subnets_cidr_blocks), var.vpc.private_subnets) : []
      security_group_ids  = var.vpc.enable_private_subnet == true ? [module.vpc.default_security_group_id] : []
    }
  }
}