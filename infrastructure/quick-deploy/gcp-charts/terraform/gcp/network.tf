# VPC with the subnet of the cluster. Its nodes are private: Cloud NAT gives them internet access to pull the
# public images.
module "vpc" {
  source = "git::https://github.com/aneoconsulting/ArmoniK.Infra.git//networking/gcp/vpc?ref=dw/upgrade-gcp-gke"

  name = "${var.prefix}-vpc"
  gke_subnet = {
    name                = "${var.prefix}-gke"
    nodes_cidr_block    = "10.43.0.0/16"
    pods_cidr_block     = "172.16.0.0/16"
    services_cidr_block = "172.17.0.0/20"
    region              = var.region
  }

  depends_on = [google_project_service.apis]
}
