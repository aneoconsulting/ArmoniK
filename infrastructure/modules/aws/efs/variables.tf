# Tags
variable "tags" {
  description = "Tags for resource"
  type        = any
  default     = {}
}

# VPC info
variable "vpc" {
  description = "AWS VPC info"
  type = object({
    id          = string
    cidr_blocks = list(string)
    subnet_ids  = list(string)
  })
}

# EFS info
variable "efs" {
  description = "EFS info"
  type = object({
    name                            = string
    kms_key_id                      = string
    performance_mode                = string # "generalPurpose" or "maxIO"
    throughput_mode                 = string #  "bursting" or "provisioned"
    provisioned_throughput_in_mibps = number
    transition_to_ia                = string
    # "AFTER_7_DAYS", "AFTER_14_DAYS", "AFTER_30_DAYS", "AFTER_60_DAYS", or "AFTER_90_DAYS"
    access_point = list(string)
  })
  validation {
    condition     = (var.efs.throughput_mode == "bursting" || (var.efs.throughput_mode == "provisioned" && var.efs.provisioned_throughput_in_mibps == null && var.efs.provisioned_throughput_in_mibps == 0))
    error_message = "When using throughput_mode=\"provisioned\", also set \"provisioned_throughput_in_mibps\"."
  }
  validation {
    condition     = contains(["generalPurpose", "maxIO"], var.efs.performance_mode)
    error_message = "Possible values for the parameter performance_mode are \"generalPurpose\" | \"maxIO\"."
  }
  validation {
    condition = contains([
      "AFTER_7_DAYS",
      "AFTER_14_DAYS",
      "AFTER_30_DAYS",
      "AFTER_60_DAYS",
      "AFTER_90_DAYS"
    ], var.efs.transition_to_ia)
    error_message = "Possible values for the parameter transition_to_ia are \"AFTER_7_DAYS\" | \"AFTER_14_DAYS\" | \"AFTER_30_DAYS\", \"AFTER_60_DAYS\" | \"AFTER_90_DAYS\"."
  }
}
