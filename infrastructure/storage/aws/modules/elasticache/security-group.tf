resource "aws_security_group" "elasticache" {
  name        = "armonik-elasticache-${var.elasticache.tag}"
  description = "Allow Redis Elasticache inbound traffic on port 6379"
  vpc_id      = var.elasticache.vpc.id
  ingress {
    description = "tcp from ArmoniK VPC"
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    cidr_blocks = var.elasticache.vpc.cidr_blocks
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags        = local.tags
}