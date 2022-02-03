# Namespace
variable "namespace" {
  description = "Namespace of ArmoniK monitoring"
  type        = string
}

# Docker image
variable "docker_image" {
  description = "Docker image for Seq"
  type        = object({
    image = string
    tag   = string
  })
  default     = {
    image = "datalust/seq"
    tag   = "2021.4"
  }
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

# Working dir
variable "working_dir" {
  description = "Working directory"
  type        = string
  default     = ".."
}