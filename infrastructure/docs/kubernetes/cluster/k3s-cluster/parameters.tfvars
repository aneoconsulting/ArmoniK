# Region
region = "us-west-2"

# Tags
tags = {
  Terraform   = "true"
  Environment = "dev"
}

# VPC
vpc_id    = "vpc-ce2e16b6"
subnet_id = "subnet-2a31bb52"

# SSH key
ssh_key = {
  private_key_path = "~/.ssh/cluster-key"
  public_key       = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDTGyONiTGbHNwt6i+mWT3vfVwrOFVj8Nu3nK5lwyBS7qJDwsh+ejCJQjVetNmWoGmHyB/byDdE0fCmkF6IXCmBcIdu+CHEVmOo0AZamjCKU9emFJDrSdILuH4xgCVKVuPyR+eftYMwWToQ1n9/vuNs8JivuGpbeYUnefAD/1/544ikmmHHORkaq24i8fvu6tfYiqYrTwvA9vPlwAhqv2aEhdD2yEKfs1BJ9d3Y88+T0XeUlWFDXCZ6mPE7c7NPmVDu5/DuN1gFuT3c+ydCIpvkUujrtRpmLi+cFHGygNt2G0N6VanJb3UNo9mk+Ng3JPXIz/Arbm1JKzeDi4slbDS/hEa/8GztrMpzmc6H7z+V2ZnO0JTt7u7tX7SRsB8wpIdNsGP7MCgxrNyhA6FYW/x4MBFIFcTC2wNwaSZnwKpI7MP9uYfprYVW2wl5cFMAG9SQqeKGK7uO3Aj9Xlfeqx0Rob355wSZ176Xf2A3Z3zXJ75VIaZIsV78cje791XWuPAXWQb09vRmAOfJ3lUCwT/n2L3ZKrf86SqIuLT98z1xAO1uz5AFp2UigwjF4idRDOwpy0ZTkTsXpWovW8awjNs85Cl6ZQF5P2J9d1apazwiRKAlpLrmbLllSQSUSBXISsCuXZdlNmfTCbUXEHoQ4S3drXeAZ5homcUvb4TYWNxDSw== iadjadj@DESKTOP-0G0N4M7"
}

# Number of workers
nb_workers = 3
