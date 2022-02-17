provider "aws" {
  region  = var.region
  profile = var.profile
}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.certificate_authority.0.data)
  token                  = module.eks.token
  #config_path            = pathexpand("~/.kube/config")
  insecure               = false
}

# package manager for kubernetes
provider "helm" {
  helm_driver = "configmap"
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.certificate_authority.0.data)
    token                  = module.eks.token
    #config_path            = pathexpand("~/.kube/config")
    insecure               = false
  }
}

/*
provider "kubernetes" {
  token    = module.eks.token
  host     = module.eks.cluster_endpoint
  insecure = true
  exec {
    api_version = "client.authentication.k8s.io/v1alpha1"
    args        = ["eks", "get-token", "--cluster-name", local.cluster_name]
    command     = "aws"
  }
}

provider "helm" {
  helm_driver = "configmap"
  kubernetes {
    token    = module.eks.token
    host     = module.eks.cluster_endpoint
    insecure = true
    exec {
      api_version = "client.authentication.k8s.io/v1alpha1"
      args        = ["eks", "get-token", "--cluster-name", local.cluster_name]
      command     = "aws"
    }
  }
}
*/