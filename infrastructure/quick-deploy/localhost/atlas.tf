# Environment variables "MONGODB_ATLAS_PUBLIC_KEY" and "MONGODB_ATLAS_PRIVATE_KEY" must be 
# set and exported for the provider to access your MongoDB Atlas cluster

provider "mongodbatlas" {}

variable "atlas" {
  description = "Atlas project parameters"
  type = object({
    cluster_name = string
    project_id   = string
  })
}

locals {
  #mongodb_url = regex("^(?:(?P<scheme>[^:/?#]+):)?(?://(?P<dns>[^/?#]*))", data.mongodbatlas_advanced_cluster.aklocal.connection_strings[0].standard_srv)
  #mongodb_url = regex("^(?:(?P<scheme>[^:/?#]+):)?(?://(?P<dns>[^/?#]*))", mongodbatlas_advanced_cluster.aklocal.connection_strings[0].standard_srv)

  atlas_outputs = {
    env_from_secret = {
      "MongoDB__User" = {
        "secret" = kubernetes_secret.mongodb_admin.metadata[0].name
        "field"  = "username"
      }
      "MongoDB__Password" = {
        secret = kubernetes_secret.mongodb_admin.metadata[0].name
        field  = "password"
      }
      "MongoDB__ConnectionString" = {
        secret = kubernetes_secret.mongodbatlas_connection_string.metadata[0].name
        field  = "string"
      }
    }

    env = {
      "Components__TableStorage" = "ArmoniK.Adapters.MongoDB.TableStorage"
      "MongoDB__Host"            = local.mongodb_url.dns
      #"MongoDB__Port"             = "27017"
      "MongoDB__Tls" = "true"
      #"MongoDB__ReplicaSet"       = "rs0"
      "MongoDB__DatabaseName"     = "database"
      "MongoDB__DirectConnection" = "false"
      #"MongoDB__CAFile"           = "/mongodb/certificate/mongodb-ca-cert"
      "MongoDB__AuthSource" = "admin"
      #"MongoDB__Sharding" = true
    }
  }
}

resource "random_string" "mongodb_admin_user" {
  length  = 8
  special = false
  numeric = false
}

resource "random_password" "mongodb_admin_password" {
  length  = 16
  special = false
}

resource "kubernetes_secret" "mongodb_admin" {
  metadata {
    name      = "mongodb-admin"
    namespace = var.namespace
  }
  data = {
    username = random_string.mongodb_admin_user.result
    password = random_password.mongodb_admin_password.result
  }
  type = "kubernetes.io/basic-auth"
}

resource "kubernetes_secret" "mongodb" {
  metadata {
    name      = "mongodb"
    namespace = var.namespace
  }
  data = {
    # "ca.pem"           = tls_self_signed_cert.root_mongodb.cert_pem
    # "mongodb.pem"      = format("%s\n%s", tls_locally_signed_cert.mongodb_certificate.cert_pem, tls_private_key.mongodb_private_key.private_key_pem)
    # "chain.pem"        = format("%s\n%s", tls_locally_signed_cert.mongodb_certificate.cert_pem, tls_self_signed_cert.root_mongodb.cert_pem)
    username = random_string.mongodb_admin_user.result
    password = random_password.mongodb_admin_password.result
    #host               = local.mongodb_dns
    #port               = 27017
    #url                = local.mongodb_url
    #number_of_replicas = local.replicas
  }
}

resource "mongodbatlas_database_user" "admin" {
  username           = random_string.mongodb_admin_user.result
  password           = random_password.mongodb_admin_password.result
  project_id         = var.atlas.project_id
  auth_database_name = "admin"

  roles {
    role_name     = "readWrite"
    database_name = "database"
  }

  roles {
    role_name     = "readWrite"
    database_name = "admin"
  }

  scopes {
    name = var.atlas.cluster_name
    type = "CLUSTER"
  }
}

# resource "mongodbatlas_advanced_cluster" "aklocal" {
#   project_id     = var.atlas.project_id
#   name           = var.atlas.cluster_name
#   cluster_type   = "REPLICASET"
#   backup_enabled = true

#   replication_specs {
#     region_configs {
#       priority      = 7
#       provider_name = "AWS"
#       region_name   = "EU_WEST_3"
#       electable_specs {
#         instance_size = "M10"
#         node_count    = 3
#       }
#     }
#   }
# }

data "mongodbatlas_advanced_cluster" "aklocal" {
  project_id = var.atlas.project_id
  name       = var.atlas.cluster_name
}
