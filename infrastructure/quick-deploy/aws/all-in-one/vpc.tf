# AWS VPC

locals {
  vpc = {
    id                 = module.vpc.id
    cidr_block_private = var.vpc.cidr_block_private
    cidr_blocks        = concat([module.vpc.cidr_block], module.vpc.pod_subnets_cidr_blocks)
    subnet_ids         = [for i in range(length(var.vpc.cidr_block_private)) : try(module.vpc.private_subnets[i], null)]
  }
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
  endpoints = {
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
      security_group_ids  = !module.vpc.enable_external_access ? [module.vpc.this.default_security_group_id] : []
    }
    ec2 = {
      service             = "ec2"
      service_type        = "Interface"
      private_dns_enabled = !module.vpc.enable_external_access
      subnet_ids          = !module.vpc.enable_external_access ? module.vpc.private_subnets : []
      security_group_ids  = !module.vpc.enable_external_access ? [module.vpc.this.default_security_group_id] : []
    }
    ecr_dkr = {
      service             = "ecr.dkr"
      service_type        = "Interface"
      private_dns_enabled = !module.vpc.enable_external_access
      subnet_ids          = !module.vpc.enable_external_access ? module.vpc.private_subnets : []
      security_group_ids  = !module.vpc.enable_external_access ? [module.vpc.this.default_security_group_id] : []
    }
    ecr_api = {
      service             = "ecr.api"
      service_type        = "Interface"
      private_dns_enabled = !module.vpc.enable_external_access
      subnet_ids          = !module.vpc.enable_external_access ? module.vpc.private_subnets : []
      security_group_ids  = !module.vpc.enable_external_access ? [module.vpc.this.default_security_group_id] : []
    }
    logs = {
      service             = "logs"
      service_type        = "Interface"
      private_dns_enabled = !module.vpc.enable_external_access
      subnet_ids          = !module.vpc.enable_external_access ? module.vpc.private_subnets : []
      security_group_ids  = !module.vpc.enable_external_access ? [module.vpc.this.default_security_group_id] : []
    }
    sts = {
      service             = "sts"
      service_type        = "Interface"
      private_dns_enabled = !module.vpc.enable_external_access
      subnet_ids          = !module.vpc.enable_external_access ? module.vpc.private_subnets : []
      security_group_ids  = !module.vpc.enable_external_access ? [module.vpc.this.default_security_group_id] : []
    }
    ssm = {
      service             = "ssm"
      service_type        = "Interface"
      private_dns_enabled = !module.vpc.enable_external_access
      subnet_ids          = !module.vpc.enable_external_access ? module.vpc.private_subnets : []
      security_group_ids  = !module.vpc.enable_external_access ? [module.vpc.this.default_security_group_id] : []
    }
    ssmmessages = {
      service             = "ssmmessages"
      service_type        = "Interface"
      private_dns_enabled = !module.vpc.enable_external_access
      subnet_ids          = !module.vpc.enable_external_access ? module.vpc.private_subnets : []
      security_group_ids  = !module.vpc.enable_external_access ? [module.vpc.this.default_security_group_id] : []
    }
    elasticloadbalancing = {
      service             = "elasticloadbalancing"
      service_type        = "Interface"
      private_dns_enabled = !module.vpc.enable_external_access
      subnet_ids          = !module.vpc.enable_external_access ? module.vpc.private_subnets : []
      security_group_ids  = !module.vpc.enable_external_access ? [module.vpc.this.default_security_group_id] : []
    }
    monitoring = {
      service             = "monitoring"
      service_type        = "Interface"
      private_dns_enabled = !module.vpc.enable_external_access
      subnet_ids          = !module.vpc.enable_external_access ? module.vpc.private_subnets : []
      security_group_ids  = !module.vpc.enable_external_access ? [module.vpc.this.default_security_group_id] : []
    }
  }
  tags = local.tags
}