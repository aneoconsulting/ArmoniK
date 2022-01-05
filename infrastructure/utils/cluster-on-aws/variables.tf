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

# SSH key
variable "ssh_key" {
  description = "Public ssh key"
  type        = string
  default     = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQD3F6tyPEFEzV0LX3X8BsXdMsQz1x2cEikKDEY0aIj41qgxMCP/iteneqXSIFZBp5vizPvaoIR3Um9xK7PGoW8giupGn+EPuxIA4cDM4vzOqOkiMPhz5XK0whEjkVzTo4+S0puvDZuwIsdiW9mxhJc7tgBNL0cYlWSYVkz4G/fslNfRPW5mYAM49f4fhtxPb5ok4Q2Lg9dPKVHO/Bgeu5woMc7RY0p1ej6D4CKFE6lymSDJpW0YHX/wqE9+cfEauh7xZcG0q9t2ta6F6fmX0agvpFyZo8aFbXeUBr7osSCJNgvavWbM/06niWrOvYX2xwWdhXmXSrbX8ZbabVohBK41 email@example.com"
}

# Merge data for cloud-init
variable "extra_userdata_merge" {
  description = "Control how cloud-init merges user-data sections"
  type        = string
  default     = "list(append)+dict(recurse_array)+str()"
}

# Number of workers
variable "nb_workers" {
  description = "Number of worker nodes"
  type        = number
  default     = 3
}