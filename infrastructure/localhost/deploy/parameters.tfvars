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

# Parameters for queue storage
queue_storage = ({
  replicas = 1,
  port     = [
    { name = "dashboard", port = 8161, target_port = 8161, protocol = "TCP" },
    { name = "openwire", port = 61616, target_port = 61616, protocol = "TCP" },
    { name = "amqp", port = 5672, target_port = 5672, protocol = "TCP" },
    { name = "stomp", port = 61613, target_port = 61613, protocol = "TCP" },
    { name = "mqtt", port = 1883, target_port = 1883, protocol = "TCP" }
  ],
  secret   = "queue-storage-secret"
})

# Parameters for shared storage
shared_storage = ({
  storage_class           = ({
    provisioner            = "kubernetes.io/no-provisioner",
    name                   = "nfs",
    volume_binding_mode    = "WaitForFirstConsumer",
    allow_volume_expansion = true
  }),
  persistent_volume       = ({
    name                             = "nfs-pv",
    persistent_volume_reclaim_policy = "Delete",
    access_modes                     = ["ReadWriteMany"],
    size                             = "10Gi",
    path                             = "/data"
  }),
  persistent_volume_claim = ({
    name         = "nfs-pvc",
    access_modes = ["ReadWriteMany"],
    size         = "2Gi"
  })
})
