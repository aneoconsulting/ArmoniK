locals {
  ecr_input_images = merge({
    cluster_autoscaler = {
      name = var.eks.docker_images.cluster_autoscaler.image,
      tag  = var.eks.docker_images.cluster_autoscaler.tag,
    },
    aws_node_termination_handler = {
      name = var.eks.docker_images.instance_refresh.image,
      tag  = var.eks.docker_images.instance_refresh.tag,
    },
    metrics_server = {
      name = var.metrics_server.image_name,
      tag  = var.metrics_server.image_tag,
    },
    keda = {
      name = var.keda.keda_image_name,
      tag  = var.keda.keda_image_tag,
    },
    keda_metrics_apiserver = {
      name = var.keda.apiserver_image_name,
      tag  = var.keda.apiserver_image_tag,
    },
    mongodb = {
      name = var.mongodb.image_name,
      tag  = var.mongodb.image_tag,
    },
  }, var.pv_efs == null ? {} : {
    efs_csi_driver = {
      name = var.pv_efs.csi_driver.images.efs_csi.name,
      tag  = var.pv_efs.csi_driver.images.efs_csi.tag,
    },
    eks_csi_livenessprobe = {
      name = var.pv_efs.csi_driver.images.livenessprobe.name,
      tag  = var.pv_efs.csi_driver.images.livenessprobe.tag,
    },
    eks_csi_node_driver_registrar = {
      name = var.pv_efs.csi_driver.images.node_driver_registrar.name,
      tag  = var.pv_efs.csi_driver.images.node_driver_registrar.tag,
    },
    eks_csi_external_provisioner = {
      name = var.pv_efs.csi_driver.images.external_provisioner.name,
      tag  = var.pv_efs.csi_driver.images.external_provisioner.tag,
    },
  })

  ecr_repositories = [ for ecr_name, image in local.ecr_input_images: {
    service_name = ecr_name

    name  = replace("${local.prefix}-${ecr_name}", "_", "-"),
    image = image.name,
    tag   = image.tag,
  }]

  ecr_images = { for i, rep in local.ecr_repositories:
    rep.service_name => {
      image = module.ecr.repositories[i],
      name  = module.ecr.repositories[i],
      tag   = rep.tag,
    }
  }
}

# AWS ECR
module "ecr" {
  source       = "../../../modules/aws/ecr"
  tags         = local.tags
  kms_key_id   = local.kms_key
  repositories = local.ecr_repositories
}
