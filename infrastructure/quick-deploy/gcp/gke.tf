locals {
  node_pools = var.gke.node_pools == null ? null : {
    for name, node_pool in var.gke.node_pools : name => merge(node_pool, {
      labels = merge(local.labels, try(node_pool.labels, {}))
      tags   = values(local.labels)
    })
  }
}

module "gke" {
  source            = "./generated/infra-modules/kubernetes/gcp/gke"
  name              = local.gke_name
  network           = module.vpc.name
  subnetwork        = module.vpc.gke_subnet_name
  ip_range_pods     = module.vpc.gke_subnet_pods_range_name
  ip_range_services = module.vpc.gke_subnet_svc_range_name
  kms_key = {
    id = local.kms_key_id
  }
  regional   = var.gke.regional
  zones      = var.gke.zones
  labels     = local.labels
  node_pools = local.node_pools
  control_plane = {
    dns_allow_external_traffic = var.gke.enable_public_gke_access
  }
  kubeconfig_path     = var.gke.generate_kubeconfig ? abspath(var.gke.kubeconfig_file) : null
  deletion_protection = false
}

resource "kubernetes_namespace" "armonik" {
  metadata {
    name = var.gke.namespace
  }
  depends_on = [module.gke]
}
