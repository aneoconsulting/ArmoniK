module "gke" {
  source               = "./generated/infra-modules/kubernetes/gcp/gke"
  name                 = local.gke_name
  network              = module.vpc.name
  subnetwork           = module.vpc.gke_subnet_name
  subnetwork_cidr      = module.vpc.gke_subnet_cidr_block
  ip_range_pods        = module.vpc.gke_subnet_pods_range_name
  ip_range_services    = module.vpc.gke_subnet_svc_range_name
  kubeconfig_path      = abspath(var.gke.kubeconfig_file)
  service_account_name = local.gke_name
  database_encryption = [
    {
      state    = "ENCRYPTED"
      key_name = var.kms_name
    }
  ]
  cluster_resource_labels    = local.labels
  node_pools_labels          = local.node_pool_labels
  node_pools_resource_labels = local.node_pool_labels
  node_pools_tags            = local.node_pool_tags
  private                    = false
}

resource "kubernetes_namespace" "armonik" {
  metadata {
    name = var.gke.namespace
  }
  depends_on = [module.gke]
}
