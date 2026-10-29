# Zonal Standard cluster: the GKE free tier covers the management fee of one zonal cluster, and node counts are
# per zone. Private nodes and no public IP endpoint: Terraform and kubectl go through the DNS endpoint,
# authenticated by IAM, so no CIDR to maintain.
module "gke" {
  source = "git::https://github.com/aneoconsulting/ArmoniK.Infra.git//kubernetes/gcp/gke?ref=dw/upgrade-gcp-gke"

  name                       = var.prefix
  description                = "ArmoniK quick deploy"
  network                    = module.vpc.name
  subnetwork                 = module.vpc.gke_subnet_name
  ip_range_pods              = module.vpc.gke_subnet_pods_range_name
  ip_range_services          = module.vpc.gke_subnet_svc_range_name
  regional                   = false
  zones                      = [var.zone]
  dns_allow_external_traffic = true
  deletion_protection        = false

  node_pools = {
    # Operators, PostgreSQL, control plane, ingress and monitoring
    system = {
      machine_type = var.node_pools.system.machine_type
      min_count    = 1
      max_count    = var.node_pools.system.max_count
      disk_type    = "pd-balanced"
    }
    # Partitions only (tainted), scaled from 0 by the cluster autoscaler as KEDA adds pods
    compute = {
      machine_type = var.node_pools.compute.machine_type
      min_count    = 0
      max_count    = var.node_pools.compute.max_count
      spot         = var.node_pools.compute.spot
      disk_type    = "pd-balanced"
      labels       = { (local.workers.key) = local.workers.value }
      taints       = [{ key = local.workers.key, value = local.workers.value, effect = "NO_SCHEDULE" }]
    }
  }

  labels = local.labels

  depends_on = [google_project_service.apis]
}
