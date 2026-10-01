locals {
  rds_major_version = split(".", var.rds.engine_version)[0]
}

resource "aws_security_group" "rds" {
  name_prefix = "${local.name}-rds-"
  description = "PostgreSQL from the EKS nodes"
  vpc_id      = module.vpc.vpc_id

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "rds_from_nodes" {
  security_group_id            = aws_security_group.rds.id
  description                  = "PostgreSQL from the EKS nodes (VPC CNI pods share the node security group)"
  ip_protocol                  = "tcp"
  from_port                    = 5432
  to_port                      = 5432
  referenced_security_group_id = module.eks.node_security_group_id
}

module "rds" {
  source  = "terraform-aws-modules/rds/aws"
  version = "~> 7.2"

  identifier = local.name

  engine                = "postgres"
  engine_version        = var.rds.engine_version
  family                = "postgres${local.rds_major_version}"
  major_engine_version  = local.rds_major_version
  instance_class        = var.rds.instance_class
  allocated_storage     = var.rds.allocated_storage
  max_allocated_storage = var.rds.max_allocated_storage
  storage_type          = "gp3"
  storage_encrypted     = true
  kms_key_id            = module.kms.key_arn

  db_name  = "armonik"
  username = "armonik"
  port     = 5432

  # Password generated and stored by RDS in Secrets Manager, as {"username", "password"}, read by ESO
  manage_master_user_password                            = true
  manage_master_user_password_rotation                   = true
  master_user_password_rotation_automatically_after_days = var.rds.password_rotation_days

  multi_az               = var.rds.multi_az
  create_db_subnet_group = true
  subnet_ids             = module.vpc.private_subnets
  vpc_security_group_ids = [aws_security_group.rds.id]

  # Core's task and result watchers stream the WAL through logical replication (pgoutput). Static
  # parameters, applied at creation since the instance is created with this parameter group.
  parameters = [
    { name = "rds.logical_replication", value = "1", apply_method = "pending-reboot" },
    { name = "max_replication_slots", value = tostring(var.rds.max_replication_slots), apply_method = "pending-reboot" },
    { name = "max_wal_senders", value = tostring(var.rds.max_replication_slots), apply_method = "pending-reboot" },
    { name = "rds.force_ssl", value = "1" },
  ]

  backup_retention_period = var.rds.backup_retention_period
  deletion_protection     = var.rds.deletion_protection
  skip_final_snapshot     = true
  apply_immediately       = true

  create_db_option_group = false
}
