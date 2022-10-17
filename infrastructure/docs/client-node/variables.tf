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
  default = {
    Terraform   = "true"
    Environment = "dev"
  }
}

# list of VM names
variable "vm_names" {
  description = "List of VM names"
  type        = list(string)
}

# Instance type
variable "instance_type" {
  description = "Instance type of client"
  type        = string
  default     = "t3.2xlarge"
}

# AMI
variable "ami" {
  description = "AMI for the client"
  type        = string
  default     = "ami-00f7e5c52c0f43726"
}

# Merge data for cloud-init
variable "extra_userdata_merge" {
  description = "Control how cloud-init merges user-data sections"
  type        = string
  default     = "list(append)+dict(recurse_array)+str()"
}
