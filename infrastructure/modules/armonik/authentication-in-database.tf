resource "kubernetes_job" "authentication_in_database" {
  depends_on = [
    kubernetes_service.ingress
  ]
  count = local.authentication_require_authentication ? 1 : 0
  metadata {
    name      = "authentication-in-database"
    namespace = var.namespace
    labels = {
      app     = "armonik"
      service = "authentication-in-database"
      type    = "monitoring"
    }
  }
  spec {
    template {
      metadata {
        name = "authentication-in-database"
        labels = {
          app     = "armonik"
          service = "authentication-in-database"
          type    = "monitoring"
        }
      }
      spec {
        node_selector = local.job_authentication_in_database_node_selector
        dynamic "toleration" {
          for_each = (local.job_authentication_in_database_node_selector != {} ? [
            for index in range(0, length(local.job_authentication_in_database_node_selector_keys)) : {
              key   = local.job_authentication_in_database_node_selector_keys[index]
              value = local.job_authentication_in_database_node_selector_values[index]
            }
          ] : [])
          content {
            key      = toleration.value.key
            operator = "Equal"
            value    = toleration.value.value
            effect   = "NoSchedule"
          }
        }
        dynamic "image_pull_secrets" {
          for_each = (var.authentication.image_pull_secrets != "" ? [1] : [])
          content {
            name = var.authentication.image_pull_secrets
          }
        }
        restart_policy = "OnFailure" # Always, OnFailure, Never
        container {
          name              = var.authentication.name
          image             = var.authentication.tag != "" ? "${var.authentication.image}:${var.authentication.tag}" : var.authentication.image
          image_pull_policy = var.authentication.image_pull_policy
          command           = ["/bin/bash", "-c", local.authentication_script]
          env {
            name  = "MongoDB_Host"
            value = local.mongodb_host
          }
          env {
            name  = "MongoDB_Port"
            value = local.mongodb_port
          }
          dynamic "env" {
            for_each = local.pod_authentication_in_database_credentials
            content {
              name = env.key
              value_from {
                secret_key_ref {
                  key      = env.value.key
                  name     = env.value.name
                  optional = false
                }
              }
            }
          }
          dynamic "volume_mount" {
            for_each = (local.mongodb_certificates_secret != "" ? [1] : [])
            content {
              name       = "mongodb-secret-volume"
              mount_path = "/mongodb"
              read_only  = true
            }
          }
          volume_mount {
            name       = "mongodb-script"
            mount_path = "/mongodb/script"
            read_only  = true
          }
        }
        dynamic "volume" {
          for_each = (local.mongodb_certificates_secret != "" ? [1] : [])
          content {
            name = "mongodb-secret-volume"
            secret {
              secret_name = local.mongodb_certificates_secret
              optional    = false
            }
          }
        }
        volume {
          name = "mongodb-script"
          config_map {
            name     = kubernetes_config_map.authmongo.0.metadata[0].name
            optional = false
          }
        }
      }
    }
    backoff_limit = 5
  }
  wait_for_completion = true
  timeouts {
    create = "2m"
    update = "2m"
  }
}

data "tls_certificate" "certificate_data" {
  count   = length(tls_locally_signed_cert.ingress_client_certificate)
  content = tls_locally_signed_cert.ingress_client_certificate[count.index].cert_pem
}

locals {
  certificates_list = [for index, cert in data.tls_certificate.certificate_data : {
    "Fingerprint" = cert.certificates[length(cert.certificates) - 1].sha1_fingerprint
    "CN"          = tls_cert_request.ingress_client_cert_request[index].subject.0.common_name
    "Username"    = local.ingress_generated_cert.names[index]
  }]
  users_list = [for index, cert in local.certificates_list : {
    "Username" = cert.Username,
    "Roles"    = [cert["Username"]]
  }]
  roles_list = [for cert in local.certificates_list : {
    RoleName    = cert["Username"],
    Permissions = local.ingress_generated_cert.permissions[cert["Username"]]
  }]
  auth_js = <<EOF
var certs_list = ${jsonencode(local.certificates_list)};
var users_list = ${jsonencode(local.users_list)};
var roles_list = ${jsonencode(local.roles_list)};
var aggregation_user = [
  {
    '$lookup': {
      'from': 'RoleData',
      'localField': 'Roles',
      'foreignField': 'RoleName',
      'as': 'RoleIds'
    }
  }, {
    '$project': {
      '_id': 0,
      'Username': 1,
      'Roles': '$RoleIds._id'
    }
  }, {
    '$out': 'UserData'
  }
];
var aggregation_certs = [
  {
    '$lookup': {
      'from': 'UserData',
      'localField': 'Username',
      'foreignField': 'Username',
      'as': 'UserId'
    }
  }, {
    '$match': {
      'UserId': {
        '$ne': null,
        '$not': {
          '$size': 0
        }
      }
    }
  }, {
    '$project': {
      '_id': 0,
      'CN': 1,
      'Fingerprint': 1,
      'UserId': {
        '$arrayElemAt': [
          '$UserId._id', 0
        ]
      }
    }
  }, {
    '$out': 'AuthData'
  }
];

// Drop
db.RoleData.drop();
db.Temp_UserData.drop();
db.Temp_AuthData.drop();
db.UserData.drop();
db.AuthData.drop();

// We need to put the certs and users in temporary tables because inline documents in pipelines are only available in Mongo 5.1
db.RoleData.insertMany(roles_list);
db.Temp_UserData.insertMany(users_list);
db.Temp_AuthData.insertMany(certs_list);

// Then we use the aggregation pipelines to populate the users and certificates with the right objectIds
db.Temp_UserData.aggregate(aggregation_user)
db.Temp_AuthData.aggregate(aggregation_certs)

//We drop the temporary tables
db.Temp_UserData.drop();
db.Temp_AuthData.drop();
  EOF

  authentication_script = <<EOF
#!/bin/bash
mongosh --tlsCAFile /mongodb/${local.mongodb_certificates_ca_filename} --tlsAllowInvalidCertificates --tlsAllowInvalidHostnames --tls --username $MongoDB_User --password $MongoDB_Password mongodb://${local.mongodb_host}:${local.mongodb_port}/database /mongodb/script/initauth.js
EOF
}

resource "kubernetes_config_map" "authmongo" {
  count = local.authentication_require_authentication ? 1 : 0
  metadata {
    name      = "mongodb-script"
    namespace = var.namespace
  }
  data = {
    "initauth.js" = local.auth_js
  }
}