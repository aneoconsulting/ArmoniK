# Region
region = "us-east-1"

# Tags
tags = {
  Terraform   = "true"
  Environment = "dev"
}

# VMs names
#vm_names = ["client"]
vm_names = ["stark", "lannister", "baratheon", "targaryen", "greyjoy", "tyrell"]

# AMI
ami = "ami-0022f774911c1d690"

# Instance type
instance_type = "c5.4xlarge"