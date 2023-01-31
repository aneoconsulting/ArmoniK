# configmap with all the variables
resource "kubernetes_config_map" "core_config" {
  metadata {
    name      = "core-configmap"
    namespace = var.namespace
  }
  data = merge(var.extra_conf.core, local.s3_object_storage, {
    Components__TableStorage             = "ArmoniK.Adapters.MongoDB.TableStorage"
    Components__ObjectStorage            = "ArmoniK.Adapters.Redis.ObjectStorage"
    Components__QueueStorage             = "ArmoniK.Adapters.Amqp.QueueStorage"
    MongoDB__CAFile                      = local.secrets.mongodb.ca_filename
    MongoDB__ReplicaSetName              = "rs0"
    MongoDB__DatabaseName                = "database"
    MongoDB__DirectConnection            = "true"
    MongoDB__Tls                         = "true"
    Redis__CaPath                        = local.secrets.redis.ca_filename
    Redis__InstanceName                  = "ArmoniKRedis"
    Redis__ClientName                    = "ArmoniK.Core"
    Redis__Ssl                           = "true"
    Amqp__CaPath                         = local.secrets.activemq.ca_filename
    Amqp__Scheme                         = "AMQPS"
    Authenticator__RequireAuthentication = local.authentication_require_authentication
    Authenticator__RequireAuthorization  = local.authentication_require_authorization
  })
}
