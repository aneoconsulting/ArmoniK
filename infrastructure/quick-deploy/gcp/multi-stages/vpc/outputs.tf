# VPC
output "vpc" {
  description = "VPC infos"
  value = {
    name                       = module.vpc.name
    gke_subnet_name            = module.vpc.gke_subnet_name
    gke_subnet_cidr_block      = module.vpc.gke_subnet_cidr_block
    gke_subnet_pods_range_name = module.vpc.gke_subnet_pods_range_name
    gke_subnet_svc_range_name  = module.vpc.gke_subnet_svc_range_name
  }
}
