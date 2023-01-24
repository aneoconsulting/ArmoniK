# configmap with all the variables
resource "kubernetes_config_map" "core_config" {
  metadata {
    name      = "core-configmap"
    namespace = var.namespace
  }
  data = merge(var.extra_conf.core, {
    Components__TableStorage                   = "ArmoniK.Adapters.MongoDB.TableStorage"
    Components__ObjectStorage                  = "ArmoniK.Adapters.Redis.ObjectStorage"
    Components__QueueStorage                   = "ArmoniK.Adapters.Amqp.QueueStorage"
    MongoDB__CAFile                            = (local.mongodb_certificates_secret != "" ? local.mongodb_ca_filename : "")
    MongoDB__ReplicaSetName                    = "rs0"
    MongoDB__DatabaseName                      = "database"
    MongoDB__DataRetention                     = "10.00:00:00"
    MongoDB__DirectConnection                  = "true"
    MongoDB__Tls                               = "true"
    MongoDB__TableStorage__PollingDelay        = "00:00:01"
    Redis__CaPath                              = (local.redis_certificates_secret != "" ? local.redis_ca_filename : "")
    Redis__InstanceName                        = "ArmoniKRedis"
    Redis__ClientName                          = "ArmoniK.Core"
    Redis__Ssl                                 = "true"
    Amqp__CaPath                               = (local.activemq_certificates_secret != "" ? local.activemq_ca_filename : "")
    Amqp__Scheme                               = "AMQPS"
    Amqp__MaxPriority                          = "10"
    Amqp__MaxRetries                           = "5"
    Amqp__QueueStorage__LockRefreshPeriodicity = "00:00:45"
    Amqp__QueueStorage__PollPeriodicity        = "00:00:10"
    Amqp__QueueStorage__LockRefreshExtension   = "00:02:00"
    Authenticator__RequireAuthentication       = local.authentication_require_authentication
    Authenticator__RequireAuthorization        = local.authentication_require_authorization
  })
}
