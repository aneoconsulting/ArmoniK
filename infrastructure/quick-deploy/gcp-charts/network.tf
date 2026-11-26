# VPC with the subnet of the cluster. Its nodes are private: Cloud NAT gives them internet access, for what does not
# go through the pull-through caches (the worker images of var.partitions outside Artifact Registry, for one).
module "vpc" {
  source = "git::https://github.com/aneoconsulting/ArmoniK.Infra.git//networking/gcp/vpc?ref=dw/gcp-charts-deploy"

  name = "${var.prefix}-vpc"
  gke_subnet = {
    name                = "${var.prefix}-gke"
    nodes_cidr_block    = "10.43.0.0/16"
    # A /24 per node (110 pods): a /16 caps the cluster at 256 nodes, ~270 for 7000 bench workers. /14: 1024 nodes.
    pods_cidr_block     = "172.20.0.0/14"
    services_cidr_block = "172.17.0.0/20"
    region              = var.region
    public_access       = true
  }
  # ~179 GiB of flow logs on 2026-11-13 (~45 $ of Networking Telemetry), for nothing the bench uses
  enable_flow_logs = false

  depends_on = [terraform_data.apis]
}
