resource "aws_vpc_peering_connection" "peering" {
  count = (var.vpc.peering.enabled ? length(var.vpc.peering.peer_vpc_ids) : 0)
  peer_owner_id = data.aws_caller_identity.current.id
  peer_vpc_id = var.vpc.peering.peer_vpc_ids[count.index]
  vpc_id = module.vpc.vpc_id
  auto_accept = true
  tags = merge(local.tags, {
    name = "Peering ${var.vpc.peering.peer_vpc_ids[count.index]} and ${module.vpc.vpc_id}"
  })
  depends_on = [module.vpc]
}