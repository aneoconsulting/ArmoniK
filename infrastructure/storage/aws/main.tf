# KMS
module "kms" {
  count  = (var.elasticache.kms_key_id == "" ? 1 : 0)
  source = "../../modules/aws/kms"
  name   = "armonik-storage-kms-${local.tag}"
}

# AWS Elasticache
module "elasticache" {
  source      = "./modules/elasticache"
  elasticache = {
    tag              = local.tag
    engine           = var.elasticache.engine
    engine_version   = var.elasticache.engine_version
    node_type        = var.elasticache.node_type
    kms_key_id       = (var.elasticache.kms_key_id != "" ? var.elasticache.kms_key_id : module.kms.0.selected.arn)
    vpc              = {
      id          = (var.elasticache.vpc.id != "" ? var.elasticache.vpc.id : var.armonik_vpc_id)
      cidr_blocks = (length(var.elasticache.vpc.cidr_blocks) != 0 ? var.elasticache.vpc.cidr_blocks : local.vpc_cidr_blocks)
      subnet_ids  = (length(var.elasticache.vpc.subnet_ids) != 0 ? var.elasticache.vpc.subnet_ids : local.vpc_private_subnet_ids)
    }
    cluster_mode     = {
      replicas_per_node_group = var.elasticache.cluster_mode.replicas_per_node_group
      num_node_groups         = var.elasticache.cluster_mode.num_node_groups
    }
    multi_az_enabled = false
    tags             = local.tags
  }
}