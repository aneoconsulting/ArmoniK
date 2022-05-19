# configmap with all the variables
resource "kubernetes_config_map" "polling_agent_config" {
  metadata {
    name      = "polling-agent-configmap"
    namespace = var.namespace
  }
  data = {
    Components__TableStorage             = "ArmoniK.Adapters.MongoDB.TableStorage"
    Components__ObjectStorage            = "ArmoniK.Adapters.Redis.ObjectStorage"
    Components__QueueStorage             = "ArmoniK.Adapters.Amqp.QueueStorage"
    ComputePlan__GrpcChannel__Address    = "/cache/armonik.sock"
    ComputePlan__GrpcChannel__SocketType = "unixsocket"
    ComputePlan__MessageBatchSize        = "1"
    target_grpc_sockets_path             = "/cache"
    target_data_path                     = "/data"
  }
}
