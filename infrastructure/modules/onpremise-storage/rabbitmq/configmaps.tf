locals {
  enabled_plugins = "[rabbitmq_management, rabbitmq_peer_discovery_k8s, rabbitmq_prometheus, rabbitmq_management_agent, rabbitmq_amqp1_0]."
#   config_file     = <<EOF
# ## DEFAULT SETTINGS ARE NOT MEANT TO BE TAKEN STRAIGHT INTO PRODUCTION
# ## see https://www.rabbitmq.com/configure.html for further information
# ## on configuring RabbitMQ

 

# ## allow access to the guest user from anywhere on the network
# ## https://www.rabbitmq.com/access-control.html#loopback-users
# ## https://www.rabbitmq.com/production-checklist.html#users
# loopback_users.guest = false

 

# ## Send all logs to stdout/TTY. Necessary to see logs when running via
# ## a container
# log.console = true
# ## Defines the threshold of RAM using at which publishers to the queue are throttled
# ## https://www.rabbitmq.com/memory.html
# vm_memory_high_watermark.relative = 0.75

# ## Defines the threshold of memory using at which publishers to the queue are throttled 
# ## https://www.rabbitmq.com/disk-alarms.html
# disk_free_limit.relative = 0.75
# EOF
  config_file = <<EOF
  default_user = guest
  default_pass = guest

  listeners.tcp.default = 5672
  management.tcp.port = 15672

  ## management.load_definitions = /etc/rabbitmq/definitions.json

  ## allow access to the guest user from anywhere on the network
  ## https://www.rabbitmq.com/access-control.html#loopback-users
  ## https://www.rabbitmq.com/production-checklist.html#users
  loopback_users.guest = none

  ## Send all logs to stdout/TTY. Necessary to see logs when running via
  ## a container
  log.console = true

  #listeners.ssl.default = 5671
  #ssl_options.cacertfile = /etc/pki/tls/RMQ-CA-cert.pem
  #ssl_options.certfile = /etc/pki/tls/RMQ-server-cert.pem
  #ssl_options.keyfile = /etc/pki/tls/RMQ-server-key.pem
  ssl_options.verify = verify_peer
  ssl_options.fail_if_no_peer_cert = true

  EOF

  /*definitions = <<EOF
  {
    "rabbit_version": "3.8.9",
    "rabbitmq_version": "3.8.9",
    "product_name": "RabbitMQ",
    "product_version": "3.8.9",
    "users": [
      {
        "name": "john123",
        "password_hash": "dfrWOajIM5i4a/f1RhtL6DA1lFPSJ82X4CbdOP3NRQCWLNXt",
        "hashing_algorithm": "rabbit_password_hashing_sha256",
        "tags": "administrator"
      }
    ],
    "vhosts": [
      {
        "name": "demo-vhost"
      }
    ],
    "permissions": [
      {
        "user": "john123",
        "vhost": "demo-vhost",
        "configure": ".*",
        "write": ".*",
        "read": ".*"
      }
    ],
    "topic_permissions": [
  
    ],
    "parameters": [
  
    ],
    "global_parameters": [
      {
        "name": "cluster_name",
        "value": "rabbit@a8d5c6e08439"
      },
      {
        "name": "internal_cluster_id",
        "value": "rabbitmq-cluster-id-gXeBLbsUC2W2tU0Bx_QY_w"
      }
    ],
    "policies": [
  
    ],
    "queues": [
      {
        "name": "demo-queue",
        "vhost": "demo-vhost",
        "durable": true,
        "auto_delete": false,
        "arguments": {
          "x-queue-mode": "lazy",
          "x-queue-type": "classic"
        }
      }
    ],
    "exchanges": [
    ],
    "bindings": [
      {
        "source": "amq.direct",
        "vhost": "demo-vhost",
        "destination": "demo-queue",
        "destination_type": "queue",
        "routing_key": "demo-queue",
        "arguments": {
        }
      }
    ]
  }
  EOF
  */
}

# configmap with all the variables
resource "kubernetes_config_map" "rabbitmq_plugins" {
  metadata {
    name      = "rabbitmq-plugins"
    namespace = var.namespace
  }
  data = {
    "enabled_plugins" = local.enabled_plugins
    "rabbitmq.conf"   = local.config_file
    #"definitions.json" = local.definitions
  }
}

# resource "kubernetes_config_map" "rabbitmq_config" {
#   metadata {
#     name      = "rabbitmq-config"
#     namespace = var.namespace
#   }
#   data = {
#     "10-default.conf"     = local.config_file
#   }
# }