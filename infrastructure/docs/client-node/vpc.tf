# Default vpc
data "aws_vpc" "default_vpc" {
  default = true
}

# default subnets
resource "aws_default_subnet" "subnet" {
  availability_zone = "${var.region}a"
}