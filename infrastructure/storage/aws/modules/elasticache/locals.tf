locals {
  tags = merge(var.elasticache.tags, { resource = "Elasticache" })
}