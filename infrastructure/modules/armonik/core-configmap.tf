# configmap with all the variables
resource "kubernetes_config_map" "core_config" {
  metadata {
    name      = "core-configmap"
    namespace = var.namespace
  }
  data = {
    Components__TableStorage                   = "ArmoniK.Adapters.MongoDB.TableStorage"
    Components__ObjectStorage                  = "ArmoniK.Adapters.Redis.ObjectStorage"
    Components__QueueStorage                   = "ArmoniK.Adapters.Amqp.QueueStorage"
    Components__LeaseProvider                  = "ArmoniK.Adapters.MongoDB.LeaseProvider"
    ComputePlan__GrpcChannel__Address          = "/cache/armonik.sock"
    ComputePlan__GrpcChannel__SocketType       = "unixsocket"
    ComputePlan__MessageBatchSize              = "1"
    target_grpc_sockets_path                   = "/cache"
    target_data_path                           = "/data"
    Serilog__MinimumLevel                      = var.logging_level
    MongoDB__Host                              = var.storage_endpoint_url.mongodb.host
    MongoDB__Port                              = var.storage_endpoint_url.mongodb.port
    MongoDB__CAFile                            = (var.storage_endpoint_url.mongodb.certificates.secret != "" ? "/mongodb/${var.storage_endpoint_url.mongodb.certificates.ca_filename}" : "")
    MongoDB__ReplicaSetName                    = "rs0"
    MongoDB__DatabaseName                      = "database"
    MongoDB__DataRetention                     = "10.00:00:00"
    MongoDB__AllowInsecureTls                  = var.storage_endpoint_url.mongodb.allow_insecure_tls
    MongoDB__DirectConnection                  = "true"
    MongoDB__Tls                               = "true"
    MongoDB__TableStorage__PollingDelay        = "00:00:01"
    Redis__EndpointUrl                         = var.storage_endpoint_url.redis.url
    Redis__CaPath                              = (var.storage_endpoint_url.redis.certificates.secret != "" ? "/redis/${var.storage_endpoint_url.redis.certificates.ca_filename}" : "")
    Redis__Timeout                             = var.storage_endpoint_url.redis.timeout
    Redis__InstanceName                        = "ArmoniKRedis"
    Redis__ClientName                          = "ArmoniK.Core"
    Redis__Ssl                                 = "true"
    Redis__SslHost                             = var.storage_endpoint_url.redis.ssl_host
    Amqp__Host                                 = var.storage_endpoint_url.activemq.host
    Amqp__Port                                 = var.storage_endpoint_url.activemq.port
    Amqp__CaPath                               = (var.storage_endpoint_url.activemq.certificates.secret != "" ? "/amqp/${var.storage_endpoint_url.activemq.certificates.ca_filename}" : "")
    Amqp__Scheme                               = "AMQPS"
    Amqp__AllowHostMismatch                    = var.storage_endpoint_url.activemq.allow_host_mismatch
    Amqp__MaxPriority                          = "10"
    Amqp__QueueStorage__LockRefreshPeriodicity = "00:00:45"
    Amqp__QueueStorage__PollPeriodicity        = "00:00:10"
    Amqp__QueueStorage__LockRefreshExtension   = "00:02:00"
  }
}
