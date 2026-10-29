variable "bucket" {
  description = "Bucket of the Terraform states, read from ../backend.tfbackend: this root reads the outputs of terraform/gcp"
  type        = string
}

variable "ingress_allowed_cidrs" {
  description = "Source CIDRs allowed on the load balancer of the ingress: the ArmoniK API, the GUI, Seq and Grafana have no authentication"
  type        = list(string)
  default     = ["0.0.0.0/0"]

  validation {
    condition     = length(var.ingress_allowed_cidrs) > 0
    error_message = "ingress_allowed_cidrs must not be empty."
  }
}

variable "versions" {
  description = "Chart versions and ArmoniK image tags"
  type = object({
    # armonik and armonik-operators, published by the ArmoniK.Infra CI from main as <version>-SNAPSHOT.<n>.sha.<commit>
    armonik = optional(string, "0.17.0-SNAPSHOT.95.sha.af5295e6")
    core    = optional(string, "0.41.3")
    gui     = optional(string, "0.16.1")
  })
  default  = {}
  nullable = false
}

variable "partitions" {
  description = "Partitions added to the chart's own (default, stream, htcmock); a worker update is a new tag here"
  type = map(object({
    # Image without its tag, registry included (docker.io/<org>/<image>, <region>-docker.pkg.dev/<project>/<repo>/<image>)
    image  = string
    tag    = string
    cpu    = optional(string, "1")
    memory = optional(string, "1Gi")
    # KEDA scales the partition on its queue length, from 0 to this many pods
    max_replicas = optional(number, 20)
  }))
  default  = {}
  nullable = false

  validation {
    condition     = alltrue([for name in keys(var.partitions) : can(regex("^[a-z0-9]+$", name))])
    error_message = "Partition names must be lowercase alphanumeric: no dash (KEDA metric names)."
  }
}
