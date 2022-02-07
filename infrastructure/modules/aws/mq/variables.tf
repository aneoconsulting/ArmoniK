# Tags
variable "tags" {
  description = "Tags for resource"
  type        = any
  default     = {}
}

# MQ name
variable "name" {
  description = "AWS MQ service name"
  type        = string
  default     = "armonik-mq"
}

# MQ parameters
variable "mq" {
  description = "MQ Service parameters"
  type        = object({
    engine_type        = string
    engine_version     = string
    host_instance_type = string
    deployment_mode    = string
    storage_type       = string
    kms_key_id         = string
    user               = object({
      password = string
      username = string
    })
    vpc                = object({
      id          = string
      cidr_blocks = list(string)
      subnet_ids  = list(string)
    })
  })
}