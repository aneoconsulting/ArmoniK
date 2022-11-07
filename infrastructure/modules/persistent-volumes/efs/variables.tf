# AWS Elastic Filesystem Service
variable "efs" {
  type = object({
    name                            = string
    kms_key_id                      = string
    performance_mode                = string
    throughput_mode                 = string
    provisioned_throughput_in_mibps = number
    transition_to_ia                = string
    access_point                    = list(string)
  })
}

# EFS Container Storage Interface (CSI) Driver
variable "csi_driver" {
  description = "EFS CSI info"
  type = object({
    name               = string
    namespace          = string
    image_pull_secrets = string
    node_selector      = any
    docker_images = object({
      efs_csi = object({
        image = string
        tag   = string
      })
      livenessprobe = object({
        image = string
        tag   = string
      })
      node_driver_registrar = object({
        image = string
        tag   = string
      })
      external_provisioner = object({
        image = string
        tag   = string
      })
    })
  })
}

# Resources
variable "resources" {
  description = "requests and limits for resources"
  type = object({
    limits = object({
      storage = string
    })
    requests = object({
      storage = string
    })
  })
}

# VPC infos
variable "vpc" {
  description = "AWS VPC info"
  type        = any
}

# EKS issuer
variable "eks_issuer" {
  description = "EKS issuer"
  type        = string
}

# Tags
variable "tags" {
  description = "Tags for EFS CSI driver"
  type        = map(string)
}