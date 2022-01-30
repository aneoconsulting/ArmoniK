resource "aws_security_group_rule" "https" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = concat([var.vpc.main_cidr_block], var.vpc.pod_cidr_block_private)
  security_group_id = module.vpc.default_security_group_id
}
