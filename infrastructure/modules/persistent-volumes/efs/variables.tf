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
    repository         = string
    version            = string
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

# VPC infos
variable "vpc" {
  description = "AWS VPC info"
  type = object({
    id                 = string
    cidr_block_private = set(string)
    cidr_blocks        = set(string)
    subnet_ids         = set(string)
  })
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
