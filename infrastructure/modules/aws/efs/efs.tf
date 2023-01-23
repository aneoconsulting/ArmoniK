resource "aws_efs_file_system" "efs" {
  creation_token                  = var.efs.name
  encrypted                       = local.encrypt
  kms_key_id                      = (local.encrypt ? var.efs.kms_key_id : null)
  performance_mode                = var.efs.performance_mode
  throughput_mode                 = var.efs.throughput_mode
  provisioned_throughput_in_mibps = var.efs.provisioned_throughput_in_mibps
  lifecycle_policy {
    transition_to_ia = var.efs.transition_to_ia
  }
  tags = local.tags
}

resource "aws_security_group" "efs" {
  name        = "${var.efs.name}-sg"
  description = "Allow EFS inbound traffic on NFS port 2049"
  vpc_id      = var.vpc.id
  ingress {
    description = "tcp from ArmoniK VPC"
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    cidr_blocks = var.vpc.cidr_blocks
  }
  tags = local.tags
}

resource "aws_efs_mount_target" "efs" {
  for_each        = data.aws_subnet.private_subnet
  file_system_id  = aws_efs_file_system.efs.id
  subnet_id       = each.value.id
  security_groups = [aws_security_group.efs.id]
}

resource "aws_efs_access_point" "efs" {
  for_each       = (var.efs.access_point != null ? toset(var.efs.access_point) : toset([]))
  file_system_id = aws_efs_file_system.efs.id
  posix_user {
    gid = 1000
    uid = 1000
  }
  root_directory {
    path = "/${each.key}"
    creation_info {
      owner_gid   = 1000
      owner_uid   = 1000
      permissions = 755
    }
  }
  tags = local.tags
}
