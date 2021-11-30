# Global parameters
namespace          = "armonik"
k8s_config_context = "default"
k8s_config_path    = "~/.kube/config"

# Object storage parameters
object_storage = ({
  replicas     = 1,
  port         = 6379,
  certificates = {
    cert_file    = "cert.crt",
    key_file     = "cert.key",
    ca_cert_file = "ca.crt"
  },
  secret       = "object-storage-secret"
})

# Table storage parameters
table_storage = ({
  replicas = 1,
  port     = 27017
})