# Region
region = "us-east-1"

# Tags
tags = {
  Terraform   = "true"
  Environment = "dev"
}

# AMI
ami = "ami-0022f774911c1d690"

# Instance type
instance_type = "c5.24xlarge"

# VPC
vpc_cidr_block = "10.0.0.0/16"
vpc_id         = "vpc-00c36658244d6e19f"
subnet_id      = "subnet-0dbcdfd490529648f"

# Private Subnet
private_subnet_cidr_block = ["10.0.1.0/24", "10.10.2.0/24", "10.10.3.0/24"]

# Public Subnet
public_subnet_cidr_block = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]


# SSH key
ssh_key          = {
  private_key_path = "~/.ssh/cluster-key"
  public_key       = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC8LMpdvbp20AXvqeHeoOmm/h1Tit/2ZEndYcVL7fwmdNtG6SxQxdkBdoFnRqdef+PpFJwuT+cZ8UnV1TMq0Iu8Umr9GAPyBhDY7oASRFXKEsd7qyZDf7Xx1lf4ozFsN3NPIvr5KeAqE/UOgCbf05R3B++JPwGTT1JENEzo2tBQyfydnzcL/B5UzP0gIMq3n8jEgjZNqcqi3N9s0hVZmUMYUFiQv9WAjH6bf+Gn/ixDSgUhf0oLfML/KgnH+nfvfaklF8yY+E0u+0FySI8T4VArAnJUj1hr9Qj2mO9rvrdxAEtP3K20T0ChcAaRSeDvhes7I8dyyHSOYXgqsYFxky9KXeHkFWU3uNNHihogZ3lelLOzRSTQpR6z29XgLSqAHnAx9O/zWPYUxmIQu3eihpob6syZRJnF7ofazuW86bcncpTvvuph+brWMg9FJAGYHV8lxyrKjHj4NFzELpvMlOBI+DIo7eJa0G3WUA3FkRaEbBWSbIeiFyKdkVHBl7Om9tc9YgR2F45dd5ddlFh6MxUDIN8N56oZ3TXWyMlCdYflW+rUwLIt02uIJwMk8dvnlNjt5B5XaXaKgi0O6tJiRej2n2R2TL+GhwvG3nTT8D0OadKd9W3B7LvZI523CGj8R644YXBI+kFMxLG/K7D3yjyqMOZ0DJLpi5ngCTKAG7WOQw== sysadmin@ANEO-5B0QJR2"
}
# Name of the EKS cluster
eks_cluster_name = ""