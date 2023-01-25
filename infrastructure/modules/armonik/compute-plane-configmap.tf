# configmap with all the variables
resource "kubernetes_config_map" "compute_plane_config" {
  metadata {
    name      = "compute-plane-configmap"
    namespace = var.namespace
  }
  data = merge(var.extra_conf.compute, {
    ComputePlane__WorkerChannel__Address    = "/cache/armonik_worker.sock"
    ComputePlane__WorkerChannel__SocketType = "unixdomainsocket"
    ComputePlane__AgentChannel__Address     = "/cache/armonik_agent.sock"
    ComputePlane__AgentChannel__SocketType  = "unixdomainsocket"
  })
}
