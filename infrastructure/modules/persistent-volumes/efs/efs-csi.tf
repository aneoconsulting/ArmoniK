resource "helm_release" "efs_csi" {
  name      = "efs-csi"
  namespace = kubernetes_service_account.efs_csi_driver.metadata.0.namespace
  chart     = "aws-efs-csi-driver"
  #repository = "https://kubernetes-sigs.github.io/aws-efs-csi-driver/"
  repository = "${path.module}/charts"
  version    = "2.3.0"

  set {
    name  = "image.repository"
    value = var.csi_driver.docker_images.efs_csi.image
  }
  set {
    name  = "image.tag"
    value = var.csi_driver.docker_images.efs_csi.tag
  }
  set {
    name  = "sidecars.livenessProbe.image.repository"
    value = var.csi_driver.docker_images.livenessprobe.image
  }
  set {
    name  = "sidecars.livenessProbe.image.tag"
    value = var.csi_driver.docker_images.livenessprobe.tag
  }
  set {
    name  = "sidecars.nodeDriverRegistrar.image.repository"
    value = var.csi_driver.docker_images.node_driver_registrar.image
  }
  set {
    name  = "sidecars.nodeDriverRegistrar.image.tag"
    value = var.csi_driver.docker_images.node_driver_registrar.tag
  }
  set {
    name  = "sidecars.csiProvisioner.image.repository"
    value = var.csi_driver.docker_images.external_provisioner.image
  }
  set {
    name  = "sidecars.csiProvisioner.image.tag"
    value = var.csi_driver.docker_images.external_provisioner.tag
  }
  set {
    name  = "imagePullSecrets"
    value = var.csi_driver.image_pull_secrets
  }

  values = [
    yamlencode(local.controller)
  ]
}