# Region
variable "region" {
  description = "Region"
  type        = string
  default     = "us-west-2"
}

# Tags
variable "tags" {
  description = "Tags for all resources"
  type        = map(string)
  default     = {
    Terraform   = "true"
    Environment = "dev"
  }
}

# Instance type
variable "instance_type" {
  description = "Instance type of client"
  type = string
  default = "t3.2xlarge"
}

# AMI
variable "ami" {
  description = "AMI for the client"
  type = string
  default = "ami-00f7e5c52c0f43726"
}

# VPC
variable "vpc_id" {
  description = "ID of an existing VPC"
  type = string
  default = ""
}

# VPC
variable "vpc_cidr_block" {
  description = "CIDR bloc of VPC to be created"
  type = string
  default = ""
}

# Subnet
variable "subnet_id" {
  description = "ID of an existing Subnet in the VPC"
  type = string
  default = ""
}

# Private Subnet
variable "private_subnet_cidr_block" {
  description = "CIDR bloc of subnet to be created"
  type = list(string)
  default = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

# Public Subnet
variable "public_subnet_cidr_block" {
  description = "CIDR bloc of subnet to be created"
  type = list(string)
  default = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
}

# SSH key
variable "ssh_key" {
  description = "ssh key"
  type        = object({
    private_key_path = string
    public_key       = string
  })
  default     = {
    private_key_path = "~/.ssh/cluster-key"
    public_key       = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQD3F6tyPEFEzV0LX3X8BsXdMsQz1x2cEikKDEY0aIj41qgxMCP/iteneqXSIFZBp5vizPvaoIR3Um9xK7PGoW8giupGn+EPuxIA4cDM4vzOqOkiMPhz5XK0whEjkVzTo4+S0puvDZuwIsdiW9mxhJc7tgBNL0cYlWSYVkz4G/fslNfRPW5mYAM49f4fhtxPb5ok4Q2Lg9dPKVHO/Bgeu5woMc7RY0p1ej6D4CKFE6lymSDJpW0YHX/wqE9+cfEauh7xZcG0q9t2ta6F6fmX0agvpFyZo8aFbXeUBr7osSCJNgvavWbM/06niWrOvYX2xwWdhXmXSrbX8ZbabVohBK41 email@example.com"
  }
}

# Merge data for cloud-init
variable "extra_userdata_merge" {
  description = "Control how cloud-init merges user-data sections"
  type        = string
  default     = "list(append)+dict(recurse_array)+str()"
}
