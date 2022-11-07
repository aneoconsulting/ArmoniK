resource "kubernetes_storage_class" "efs_storage_class" {
  metadata {
    name = "efs-sc"
    labels = {
      app     = "persistent-volume"
      type    = "storage-class"
      service = "efs"
    }
  }
  storage_provisioner = "efs.csi.aws.com"
  parameters = {
    provisioningMode = "efs-ap"
    fileSystemId     = module.efs.id
    directoryPerms   = "700"
    gidRangeStart    = "1000"                  # optional
    gidRangeEnd      = "2000"                  # optional
    basePath         = "/dynamic_provisioning" # optional
  }
}