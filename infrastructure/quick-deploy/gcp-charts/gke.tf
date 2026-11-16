# Standard cluster, regional control plane, nodes in one zone. Private nodes, private
# IP endpoint: Terraform and kubectl go through the DNS endpoint, authenticated by IAM, so no CIDR to maintain.
#
# Nodes: a small static pool for kube-system, everything else from the ComputeClasses of compute-classes.tf. The
# cluster default class places the pods that select none on the class named "default".
module "gke" {
  source = "git::https://github.com/aneoconsulting/ArmoniK.Infra.git//kubernetes/gcp/gke?ref=dw/gcp-charts-deploy"

  name              = var.prefix
  description       = "ArmoniK quick deploy"
  network           = module.vpc.name
  subnetwork        = module.vpc.gke_subnet_name
  ip_range_pods     = module.vpc.gke_subnet_pods_range_name
  ip_range_services = module.vpc.gke_subnet_svc_range_name
  # Regional control plane (replicated, ~0.10 $/h more than the free zonal one), nodes in the single zone of the
  # database. The zonal control plane resizes itself when the cluster passes ~50 nodes: API down 2 x 4 min, HPA and
  # KEDA frozen (autoscaling bench, 2026-11-12). Changing it recreates the cluster.
  regional            = true
  region              = var.region
  zones               = [var.zone]
  deletion_protection = false
  labels              = local.labels

  control_plane = {
    dns_allow_external_traffic = true
  }

  autoscaling = {
    default_compute_class = true
  }

  # System logs only: the pod logs go to Seq through fluent-bit. Under load the workloads wrote ~186 GiB to Cloud
  # Logging in a day (fluent-bit echoing every line on its stdout, agents logging an error on each health check).
  observability = {
    logging_components = ["SYSTEM_COMPONENTS"]
  }

  node_pools = {
    system = {
      machine_type = var.system_pool.machine_type
      min_count    = 1
      max_count    = var.system_pool.max_count
    }
  }

  # No depends_on on the APIs: it would defer the data sources of the module to the apply, and the keys of its node
  # role bindings derive from the project they read. The cluster waits for the APIs through module.vpc anyway.
}

# Created here rather than by Helm: the Grafana Secret and the S3 credentials Secret of the gcs module go in it
resource "kubernetes_namespace_v1" "armonik" {
  metadata {
    name = local.namespaces.armonik
  }
}
