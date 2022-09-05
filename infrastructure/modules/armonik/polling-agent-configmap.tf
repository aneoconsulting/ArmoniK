# configmap with all the variables
resource "kubernetes_config_map" "polling_agent_config" {
  metadata {
    name      = "polling-agent-configmap"
    namespace = var.namespace
  }
  data = {
    Components__TableStorage       = "ArmoniK.Adapters.MongoDB.TableStorage"
    Components__ObjectStorage      = "ArmoniK.Adapters.Redis.ObjectStorage"
    Components__QueueStorage       = "ArmoniK.Adapters.Amqp.QueueStorage"
    ComputePlane__MessageBatchSize = "1"
    InitWorker__WorkerCheckRetries = "10" # TODO: make it a variable
    InitWorker__WorkerCheckDelay   = "00:00:10" # TODO: make it a variable
    Amqp__LinkCredit               = "2"
    Pollster__GraceDelay           = "00:00:15"
  }
}
