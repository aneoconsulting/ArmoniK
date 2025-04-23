# Environment variables "MONGODB_ATLAS_PUBLIC_KEY" and "MONGODB_ATLAS_PRIVATE_KEY" must be 
# set and exported for the provider to access your MongoDB Atlas cluster
provider "mongodbatlas" {}

variable "atlas" {
  description = "Atlas project parameters"
  type = object({
    cluster_name = string
    project_id   = string
  })
  default = null
}

locals {
  # Only process Atlas data when using Atlas deployment
  private_endpoints = local.mongodb_type == "atlas" ? flatten([for cs in data.mongodbatlas_advanced_cluster.akaws[0].connection_strings : cs.private_endpoint]) : []
  connection_strings = local.mongodb_type == "atlas" ? [
    for pe in local.private_endpoints : pe.srv_connection_string
    if contains([for e in pe.endpoints : e.endpoint_id], module.vpce.endpoints["mongodb_atlas"].id)
  ] : []
  connection_string = length(local.connection_strings) > 0 ? local.connection_strings[0] : ""
  mongodb_url       = local.connection_string != "" ? regex("^(?:(?P<scheme>[^:/?#]+):)?(?://(?P<dns>[^/?#]*))", local.connection_string) : { scheme = "", dns = "" }

  # IMPORTANT FIX: Only create atlas_outputs when using Atlas deployment type
  atlas_outputs = local.mongodb_type == "atlas" ? {
    env_from_secret = {
      "MongoDB__User" = {
        secret = kubernetes_secret.mongodb_admin[0].metadata[0].name
        field  = "username"
      }
      "MongoDB__Password" = {
        secret = kubernetes_secret.mongodb_admin[0].metadata[0].name
        field  = "password"
      }
      "MongoDB__ConnectionString" = {
        secret = kubernetes_secret.mongodbatlas_connection_string[0].metadata[0].name
        field  = "string"
      }
    }
    env = {
      "Components__TableStorage"  = "ArmoniK.Adapters.MongoDB.TableStorage"
      "MongoDB__Host"             = local.mongodb_url.dns
      "MongoDB__Tls"              = "true"
      "MongoDB__DatabaseName"     = "database"
      "MongoDB__DirectConnection" = "false"
      "MongoDB__AuthSource"       = "admin"
      "MongoDB__Sharding"         = "true"
      #"MongoDB__Port"             = "27017"
      #"MongoDB__ReplicaSet"       = "rs0"
      #"MongoDB__CAFile"           = "/mongodb/certificate/mongodb-ca-cert"
    }
    } : {
    env_from_secret = {}
    env             = {}
  }
}

resource "random_string" "mongodb_admin_user" {
  count   = local.mongodb_type == "atlas" ? 1 : 0
  length  = 8
  special = false
  numeric = false
}

resource "random_password" "mongodb_admin_password" {
  count   = local.mongodb_type == "atlas" ? 1 : 0
  length  = 16
  special = false
}

resource "kubernetes_secret" "mongodb_admin" {
  count = local.mongodb_type == "atlas" ? 1 : 0
  metadata {
    name      = "mongodb-admin"
    namespace = local.namespace
  }
  data = {
    username = random_string.mongodb_admin_user[0].result
    password = random_password.mongodb_admin_password[0].result
  }
  type = "kubernetes.io/basic-auth"
}

resource "kubernetes_secret" "mongodbatlas_connection_string" {
  count = local.mongodb_type == "atlas" ? 1 : 0
  metadata {
    name      = "mongodbatlas-connection-string"
    namespace = local.namespace
  }
  data = {
    string = "mongodb+srv://${random_string.mongodb_admin_user[0].result}:${random_password.mongodb_admin_password[0].result}@${local.mongodb_url.dns}/database"
  }
}


resource "kubernetes_secret" "mongodb" {
  count = local.mongodb_type == "atlas" ? 1 : 0
  metadata {
    name      = "mongodb"
    namespace = local.namespace
  }
  data = {
    # "ca.pem"           = tls_self_signed_cert.root_mongodb.cert_pem
    # "mongodb.pem"      = format("%s\n%s", tls_locally_signed_cert.mongodb_certificate.cert_pem, tls_private_key.mongodb_private_key.private_key_pem)
    # "chain.pem"        = format("%s\n%s", tls_locally_signed_cert.mongodb_certificate.cert_pem, tls_self_signed_cert.root_mongodb.cert_pem)
    username = random_string.mongodb_admin_user[0].result
    password = random_password.mongodb_admin_password[0].result
    #host               = local.mongodb_dns
    #port               = 27017
    #url                = local.mongodb_url
    #number_of_replicas = local.replicas
  }
}

resource "mongodbatlas_database_user" "admin" {
  count              = local.mongodb_type == "atlas" ? 1 : 0
  username           = random_string.mongodb_admin_user[0].result
  password           = random_password.mongodb_admin_password[0].result
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

  # roles {
  #   role_name     = "enableSharding"
  #   database_name = "admin"
  # }

  scopes {
    name = var.atlas.cluster_name
    type = "CLUSTER"
  }
}

# resource "mongodbatlas_advanced_cluster" "akaws" {
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
#   depends_on = [mongodbatlas_privatelink_endpoint_service.pe_service]
# }

data "mongodbatlas_advanced_cluster" "akaws" {
  count      = local.mongodb_type == "atlas" ? 1 : 0
  project_id = var.atlas.project_id
  name       = var.atlas.cluster_name
  depends_on = [mongodbatlas_privatelink_endpoint_service.pe_service]
}

## Private endpoint creation

resource "mongodbatlas_privatelink_endpoint" "pe" {
  count         = local.mongodb_type == "atlas" ? 1 : 0
  project_id    = var.atlas.project_id
  provider_name = "AWS"
  region        = var.region
}

resource "mongodbatlas_privatelink_endpoint_service" "pe_service" {
  count               = local.mongodb_type == "atlas" ? 1 : 0
  project_id          = mongodbatlas_privatelink_endpoint.pe[0].project_id
  private_link_id     = mongodbatlas_privatelink_endpoint.pe[0].id
  endpoint_service_id = module.vpce.endpoints["mongodb_atlas"].id
  provider_name       = "AWS"
  depends_on          = [mongodbatlas_privatelink_endpoint.pe, module.vpce]
}
