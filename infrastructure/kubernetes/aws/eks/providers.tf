provider "aws" {
  region                  = var.region
  shared_credentials_file = pathexpand(".aws/credentials")
  profile                 = var.profile
}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.certificate_authority.0.data)
  token                  = module.eks.token
}

# package manager for kubernetes
provider "helm" {
  helm_driver = "configmap"
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.certificate_authority.0.data)
    token                  = module.eks.token
  }
}