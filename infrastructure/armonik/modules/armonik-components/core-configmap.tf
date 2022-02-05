# configmap with all the variables
resource "kubernetes_config_map" "core_config" {
  metadata {
    name      = "core-configmap"
    namespace = var.namespace
  }
  data = {
    Components__TableStorage                   = "ArmoniK.Adapters.${var.storage_adapters.table}"
    Components__ObjectStorage                  = "ArmoniK.Adapters.${var.storage_adapters.object}"
    Components__QueueStorage                   = "ArmoniK.Adapters.${var.storage_adapters.queue}"
    Components__LeaseProvider                  = "ArmoniK.Adapters.${var.storage_adapters.lease_provider}"
    ComputePlan__GrpcChannel__Address          = "/cache/armonik.sock"
    ComputePlan__GrpcChannel__SocketType       = "unixsocket"
    ComputePlan__MessageBatchSize              = "1"
    target_grpc_sockets_path                   = "/cache"
    target_data_path                           = "/data"
    Serilog__MinimumLevel                      = "${var.logging_level}"
    Redis__EndpointUrl                         = "${var.storage_endpoint_url.redis.url}"
    Redis__CredentialsPath                     = "/redis/redis_credentials"
    Redis__Timeout                             = "3000"
    Redis__InstanceName                        = "ArmoniKRedis"
    Redis__ClientName                          = "ArmoniK.Core"
    Amqp__Host                                 = "${var.storage_endpoint_url.activemq.host}"
    Amqp__Port                                 = "${var.storage_endpoint_url.activemq.port}"
    Amqp__CredentialsPath                      = "/amqp/amqp_credentials"
    Amqp__MaxPriority                          = "10"
    Amqp__QueueStorage__LockRefreshPeriodicity = "00:00:45"
    Amqp__QueueStorage__PollPeriodicity        = "00:00:10"
    Amqp__QueueStorage__LockRefreshExtension   = "00:02:00"
    MongoDB__Host                              = "${var.storage_endpoint_url.mongodb.host}"
    MongoDB__Port                              = "${var.storage_endpoint_url.mongodb.port}"
    MongoDB__CredentialsPath                   = "/mongodb/mongodb_credentials"
    MongoDB__ReplicaSetName                    = "rs0"
    MongoDB__DatabaseName                      = "database"
    MongoDB__DataRetention                     = "10.00:00:00"
    MongoDB__TableStorage__PollingDelay        = "00:00:01"
  }
}
