resource "aws_elasticache_subnet_group" "elasticache" {
  description = "Subnet ids for IO of ArmoniK AWS Elasticache"
  name        = "armonik-elasticache-io-${var.elasticache.tag}"
  subnet_ids  = var.elasticache.vpc.subnet_ids
  tags        = local.tags
}