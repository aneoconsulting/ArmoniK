# AWS VPC

locals {
  vpc = {
    id                 = module.vpc.id
    cidr_block_private = var.vpc.cidr_block_private
    cidr_blocks        = concat([module.vpc.cidr_block], module.vpc.pod_subnets_cidr_blocks)
    subnet_ids         = [for i in range(length(var.vpc.cidr_block_private)) : try(module.vpc.private_subnets[i], null)]
  }

  # Conditionally create MongoDB Atlas endpoints
  mongodb_atlas_endpoint = local.mongodb_type == "atlas" ? {
    service             = mongodbatlas_privatelink_endpoint.pe[0].endpoint_service_name
    service_type        = "Interface"
    private_dns_enabled = true
    subnet_ids          = local.atlas_privatelink_subnets
    security_group_ids  = [module.eks.node_security_group_id]
  } : null
}

module "vpc" {
  source                                          = "./generated/infra-modules/networking/aws/vpc"
  name                                            = "${local.prefix}-vpc"
  eks_name                                        = "${local.prefix}-eks"
  cidr                                            = var.vpc.main_cidr_block
  private_subnets                                 = var.vpc.cidr_block_private
  public_subnets                                  = var.vpc.cidr_block_public
  pod_subnets                                     = var.vpc.pod_cidr_block_private
  flow_log_cloudwatch_log_group_kms_key_id        = local.kms_key
  flow_log_cloudwatch_log_group_retention_in_days = var.vpc.flow_log_cloudwatch_log_group_retention_in_days
  use_karpenter                                   = true
  tags                                            = local.tags
}

module "vpce" {
  source = "./generated/infra-modules/networking/aws/vpce"
  vpc_id = module.vpc.id
  endpoints = merge({
    s3 = {
      service      = "s3"
      service_type = "Gateway"
      route_table_ids = flatten([
        module.vpc.this.intra_route_table_ids,
        module.vpc.this.private_route_table_ids,
        module.vpc.this.public_route_table_ids
      ])
      auto_accept     = false
      policy          = null
      ip_address_type = null
      tags            = { vpce = "s3" }
    }
    ec2_autoscaling = {
      service             = "autoscaling"
      service_type        = "Interface"
      private_dns_enabled = !module.vpc.enable_external_access
      subnet_ids          = !module.vpc.enable_external_access ? module.vpc.private_subnets : []
      security_group_ids  = [module.vpc.this.default_security_group_id]
    }
    ec2 = {
      service             = "ec2"
      service_type        = "Interface"
      private_dns_enabled = !module.vpc.enable_external_access
      subnet_ids          = !module.vpc.enable_external_access ? module.vpc.private_subnets : []
      security_group_ids  = [module.vpc.this.default_security_group_id]
    }
    ecr_dkr = {
      service             = "ecr.dkr"
      service_type        = "Interface"
      private_dns_enabled = !module.vpc.enable_external_access
      subnet_ids          = !module.vpc.enable_external_access ? module.vpc.private_subnets : []
      security_group_ids  = [module.vpc.this.default_security_group_id]
    }
    ecr_api = {
      service             = "ecr.api"
      service_type        = "Interface"
      private_dns_enabled = !module.vpc.enable_external_access
      subnet_ids          = !module.vpc.enable_external_access ? module.vpc.private_subnets : []
      security_group_ids  = [module.vpc.this.default_security_group_id]
    }
    logs = {
      service             = "logs"
      service_type        = "Interface"
      private_dns_enabled = !module.vpc.enable_external_access
      subnet_ids          = !module.vpc.enable_external_access ? module.vpc.private_subnets : []
      security_group_ids  = [module.vpc.this.default_security_group_id]
    }
    sts = {
      service             = "sts"
      service_type        = "Interface"
      private_dns_enabled = !module.vpc.enable_external_access
      subnet_ids          = !module.vpc.enable_external_access ? module.vpc.private_subnets : []
      security_group_ids  = [module.vpc.this.default_security_group_id]
    }
    ssm = {
      service             = "ssm"
      service_type        = "Interface"
      private_dns_enabled = !module.vpc.enable_external_access
      subnet_ids          = !module.vpc.enable_external_access ? module.vpc.private_subnets : []
      security_group_ids  = [module.vpc.this.default_security_group_id]
    }
    ssmmessages = {
      service             = "ssmmessages"
      service_type        = "Interface"
      private_dns_enabled = !module.vpc.enable_external_access
      subnet_ids          = !module.vpc.enable_external_access ? module.vpc.private_subnets : []
      security_group_ids  = [module.vpc.this.default_security_group_id]
    }
    elasticloadbalancing = {
      service             = "elasticloadbalancing"
      service_type        = "Interface"
      private_dns_enabled = !module.vpc.enable_external_access
      subnet_ids          = !module.vpc.enable_external_access ? module.vpc.private_subnets : []
      security_group_ids  = [module.vpc.this.default_security_group_id]
    }
    monitoring = {
      service             = "monitoring"
      service_type        = "Interface"
      private_dns_enabled = !module.vpc.enable_external_access
      subnet_ids          = !module.vpc.enable_external_access ? module.vpc.private_subnets : []
      security_group_ids  = [module.vpc.this.default_security_group_id]
    }
    },
    local.mongodb_type == "atlas" ? {
      mongodb_atlas = {
        service             = mongodbatlas_privatelink_endpoint.pe[0].endpoint_service_name
        service_type        = "Interface"
        private_dns_enabled = true
        subnet_ids          = local.atlas_privatelink_subnets
        security_group_ids  = [module.eks.node_security_group_id]
      }
    } : {}
  )

  tags       = local.tags
  depends_on = [module.vpc, mongodbatlas_privatelink_endpoint.pe, module.vpc]
}

data "aws_subnet" "private_subnets" {
  count = length(module.vpc.private_subnets)
  id    = module.vpc.private_subnets[count.index]
}

locals {
  ## This workaround because Atlas private link endpoint's subnets have to be in different availability zones
  az_subnets_map            = transpose({ for subnet in data.aws_subnet.private_subnets : subnet.id => [subnet.availability_zone] })
  atlas_privatelink_subnets = [for az in local.az_subnets_map : az[0]]
}

# resource "random_shuffle" "subnet_per_az" {
#   for_each = local.subnets_az_map
#   input        = each.value
#   result_count = 1
#   depends_on = [ data.aws_subnet.private_subnets ]
# }