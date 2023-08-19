module "gke" {
  source            = "./generated/infra-modules/kubernetes/gcp/cluster"
  name              = local.gke_name
  regional          = true
  region            = var.region
  project_id        = var.project
  network           = module.vpc.name
  subnetwork        = module.vpc.gke_subnet_name
  ip_range_pods     = module.vpc.gke_subnet_pods_range_name
  ip_range_services = module.vpc.gke_subnet_svc_range_name
  kubeconfig_path   = abspath(var.gke.kubeconfig_file)
  #  enable_private_endpoint         = true
  #  enable_private_nodes            = true
  create_service_account          = true
  service_account_name            = local.gke_name
  grant_registry_access           = true
  remove_default_node_pool        = true
  initial_node_count              = 0
  enable_vertical_pod_autoscaling = true
  cluster_autoscaling             = var.gke.cluster_autoscaling
  database_encryption = [
    {
      state    = "ENCRYPTED"
      key_name = var.kms_name
    }
  ]
  cluster_resource_labels = local.labels
}

resource "kubernetes_namespace" "armonik" {
  metadata {
    name = var.gke.namespace
  }
  depends_on = [module.gke]
}
