variable "region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-3"
}

variable "profile" {
  description = "AWS CLI profile, null to use the environment credentials"
  type        = string
  default     = null
}

variable "prefix" {
  description = "Name prefix of every resource of the deployment"
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,30}$", var.prefix))
    error_message = "prefix must be lowercase alphanumeric with dashes, 2 to 31 characters, starting with a letter."
  }
}

variable "namespace" {
  description = "Namespace of the ArmoniK release, where the Pod Identity associations bind the ArmoniK service accounts"
  type        = string
  default     = "armonik"
}

variable "operators_namespace" {
  description = "Namespace of the armonik-operators release"
  type        = string
  default     = "armonik-operators"
}

variable "tags" {
  description = "Tags added to every resource"
  type        = map(string)
  default     = {}
}

variable "vpc" {
  description = "VPC parameters"
  type = object({
    cidr               = optional(string, "10.0.0.0/16")
    single_nat_gateway = optional(bool, true)
    flow_logs          = optional(bool, false)
    # Interface endpoints (ecr.api, ecr.dkr, sts, sqs...), to keep that traffic off the NAT gateway
    interface_endpoints = optional(list(string), [])
  })
  default = {}
}

variable "eks" {
  description = "EKS parameters"
  type = object({
    kubernetes_version           = optional(string, "1.35")
    endpoint_public_access       = optional(bool, true)
    endpoint_public_access_cidrs = optional(list(string), ["0.0.0.0/0"])
    # IAM principals granted cluster admin, on top of the identity running terraform
    admin_principal_arns   = optional(list(string), [])
    log_types              = optional(list(string), ["api", "audit", "authenticator"])
    log_retention_in_days  = optional(number, 7)
    system_instance_types  = optional(list(string), ["m7i.large"])
    system_node_group_size = optional(number, 2)
  })
  default = {}
}

variable "rds" {
  description = "RDS PostgreSQL parameters"
  type = object({
    engine_version          = optional(string, "18")
    instance_class          = optional(string, "db.m7g.large")
    allocated_storage       = optional(number, 50)
    max_allocated_storage   = optional(number, 200)
    multi_az                = optional(bool, false)
    backup_retention_period = optional(number, 1)
    deletion_protection     = optional(bool, false)
    # Two slots per control-plane pod serving the events API (task and result watchers)
    max_replication_slots = optional(number, 20)
    # ArmoniK pods read the password at startup only, so every rotation needs a restart
    password_rotation_days = optional(number, 365)
  })
  default = {}
}

variable "registry_credentials" {
  description = "Upstream credentials of the ECR pull-through cache, required by AWS for Docker Hub and GitHub"
  type = object({
    docker_hub = object({
      username     = string
      access_token = string
    })
    github = object({
      username     = string
      access_token = string
    })
  })
  ephemeral = true
  sensitive = true
}

variable "registry_credentials_version" {
  description = "Bump to push new registry_credentials, which are write-only and never stored in the state"
  type        = number
  default     = 1
}
