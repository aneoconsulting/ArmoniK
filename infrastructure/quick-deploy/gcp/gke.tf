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
      key_name = local.kms_key_id
    }
  ]
  regional                   = var.gke.regional
  zones                      = var.gke.zones
  cluster_resource_labels    = local.labels
  node_pools_tags            = local.node_pools_tags
  node_pools_labels          = local.node_pools_labels
  node_pools_resource_labels = local.node_pools_labels
  node_pools_taints          = var.gke.node_pools_taints
  private                    = !var.gke.enable_public_gke_access
  autopilot                  = var.gke.enable_gke_autopilot
  node_pools                 = var.gke.node_pools
}

resource "kubernetes_namespace" "armonik" {
  metadata {
    name = var.gke.namespace
  }
  depends_on = [module.gke]
}
