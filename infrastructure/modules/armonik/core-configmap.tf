# configmap with all the variables
resource "kubernetes_config_map" "core_config" {
  metadata {
    name      = "core-configmap"
    namespace = var.namespace
  }
  data = merge(var.extra_conf.core, {
    Components__TableStorage                    = local.table_storage_adapter
    Components__ObjectStorage                   = local.object_storage_adapter
    Components__QueueAdaptorSettings__ClassName = local.queue_storage_adapter
    MongoDB__CAFile                             = local.table_storage_adapter_from_secret == "mongodb" ? local.secrets.mongodb.ca_filename : ""
    MongoDB__ReplicaSet                         = "rs0"
    MongoDB__DatabaseName                       = "database"
    MongoDB__DirectConnection                   = "false"
    MongoDB__Tls                                = "true"
    Redis__CaPath                               = local.object_storage_adapter_from_secret == "redis" ? local.secrets.redis.ca_filename : ""
    Redis__InstanceName                         = "ArmoniKRedis"
    Redis__ClientName                           = "ArmoniK.Core"
    Redis__Ssl                                  = "true"
    Amqp__CaPath                                = local.queue_storage_adapter_from_secret == "amqp" ? local.secrets.activemq.ca_filename : ""
    Amqp__Scheme                                = "AMQPS"
    Authenticator__RequireAuthentication        = local.authentication_require_authentication
    Authenticator__RequireAuthorization         = local.authentication_require_authorization
  })
}
