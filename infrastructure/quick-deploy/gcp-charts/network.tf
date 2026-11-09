# VPC with the subnet of the cluster. Its nodes are private: Cloud NAT gives them internet access, for what does not
# go through the pull-through caches (the worker images of var.partitions outside Artifact Registry, for one).
module "vpc" {
  source = "git::https://github.com/aneoconsulting/ArmoniK.Infra.git//networking/gcp/vpc?ref=dw/gcp-charts-deploy"

  name = "${var.prefix}-vpc"
  gke_subnet = {
    name                = "${var.prefix}-gke"
    nodes_cidr_block    = "10.43.0.0/16"
    pods_cidr_block     = "172.16.0.0/16"
    services_cidr_block = "172.17.0.0/20"
    region              = var.region
    public_access       = true
  }

  depends_on = [terraform_data.apis]
}
