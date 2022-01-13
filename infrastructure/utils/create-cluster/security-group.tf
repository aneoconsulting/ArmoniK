# Node Port for kubernetes services
locals {
  #node_port = range(30000-32768)
  node_port_tcp = [179, 6379, 5672, 8161, 27017, 5001, 8080, 2379, 2380, 10250, 10251, 10252, 10255, 443, 80, 53, 9153]
  node_port_udp = [8285, 8472, 53, 9153]
}

# For worker
resource "aws_security_group" "worker_sg" {
  name        = "worker"
  description = "Allow SSH inbound traffic"
  vpc_id      = data.aws_vpc.default_vpc.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# For master
resource "aws_security_group" "master_sg" {
  name        = "master"
  description = "Allow SSH, NFS and Kube inbound traffic"
  vpc_id      = data.aws_vpc.default_vpc.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "NFS"
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.default_vpc.cidr_block]
  }

  ingress {
    description = "Kube"
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# For services
resource "aws_security_group" "services_sg" {
  name        = "services"
  description = "Allow Redis, ActiveMQ, MongoDB and control plane inbound traffic"
  vpc_id      = data.aws_vpc.default_vpc.id

  dynamic "ingress" {
    for_each = local.node_port_tcp
    content {
      description = "ArmoniK services"
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  dynamic "ingress" {
    for_each = local.node_port_udp
    content {
      description = "ArmoniK services"
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "udp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
}

