# Namespace
variable "namespace" {
  description = "Namespace of ArmoniK monitoring"
  type        = string
}

# Parameters for Seq
variable "seq" {
  description = "Parameters of Seq"
  type        = object({
    replicas = number
    port     = list(object({
      name        = string
      port        = number
      target_port = number
      protocol    = string
    }))
  })
  default     = {
    replicas = 1
    port     = [
      { name = "ingestion", port = 5341, target_port = 5341, protocol = "TCP" },
      { name = "web", port = 8080, target_port = 80, protocol = "TCP" }
    ]
  }
}