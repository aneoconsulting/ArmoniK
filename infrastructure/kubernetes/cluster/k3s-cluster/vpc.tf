/*# Default vpc
data "aws_vpc" "default_vpc" {
  default = true
}

# default subnets
resource "aws_default_subnet" "master_subnet" {
  availability_zone = "us-west-2a"
}

resource "aws_default_subnet" "worker_subnet" {
  availability_zone = "us-west-2b"
}*/

# Default vpc
data "aws_vpc" "default_vpc" {
  id = var.vpc_id
}

# default subnets
data "aws_subnet" "master_subnet" {
  id = var.subnet_id
}

data "aws_subnet" "worker_subnet" {
  id = var.subnet_id
}