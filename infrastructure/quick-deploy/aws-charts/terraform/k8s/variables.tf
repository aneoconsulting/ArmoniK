variable "bucket" {
  description = "Bucket of the Terraform states, read from ../backend.tfbackend: this root reads the outputs of terraform/aws"
  type        = string
}

variable "region" {
  description = "Region of that bucket, from ../backend.tfbackend (the deployment's region comes from terraform/aws)"
  type        = string
}

variable "profile" {
  description = "AWS CLI profile, null to use the environment credentials"
  type        = string
  default     = null
}

variable "ingress_allowed_cidrs" {
  description = "Source CIDRs allowed on the NLB: the ArmoniK API, the GUI, Seq and Grafana have no authentication"
  type        = list(string)

  validation {
    condition     = length(var.ingress_allowed_cidrs) > 0
    error_message = "ingress_allowed_cidrs must not be empty: 0.0.0.0/0 opens the NLB to everyone."
  }
}

variable "versions" {
  description = "Chart versions and ArmoniK image tags"
  type = object({
    karpenter = optional(string, "1.14.1")
    lbc       = optional(string, "3.5.0")
    # armonik and armonik-operators, published by the ArmoniK.Infra CI from main as <version>-SNAPSHOT.<n>.sha.<commit>
    armonik = optional(string, "0.17.0-SNAPSHOT.83.sha.a2a8a097")
    core    = optional(string, "0.41.3")
    gui     = optional(string, "0.16.1")
  })
  default = {}
}

variable "partitions" {
  description = "Partitions added to the chart's own (default, stream, htcmock); a worker update is a new tag here"
  type = map(object({
    # Image without its tag, registry included (e.g. the workers repository of the outputs)
    image  = string
    tag    = string
    cpu    = optional(string, "1")
    memory = optional(string, "1Gi")
    # KEDA scales the partition on its queue length, from 0 to this many pods
    max_replicas = optional(number, 50)
  }))
  default = {}

  validation {
    condition     = alltrue([for name in keys(var.partitions) : can(regex("^[a-z0-9]+$", name))])
    error_message = "Partition names must be lowercase alphanumeric: no dash (KEDA metric names)."
  }
}

variable "postgresql_connection_options" {
  description = "Npgsql options appended to Core's connection string (e.g. \"No Reset On Close=true;Max Auto Prepare=100;Auto Prepare Min Usages=2\"); empty keeps Core's own connection string"
  type        = string
  default     = ""
}
