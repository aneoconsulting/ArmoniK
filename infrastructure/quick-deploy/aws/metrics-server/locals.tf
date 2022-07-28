locals {
  # metrics server
  namespace          = try(var.namespace, "kube-system")
  image              = try(var.docker_image.image, "k8s.gcr.io/metrics-server/metrics-server")
  tag                = try(var.docker_image.tag, "v0.6.1")
  image_pull_secrets = try(var.image_pull_secrets, "")
  node_selector      = try(var.node_selector, {})
  default_args       = try(var.default_args, []) == [] ? [
    "--cert-dir=/tmp",
    "--kubelet-preferred-address-types=InternalIP,ExternalIP,Hostname",
    "--kubelet-use-node-status-port",
    "--metric-resolution=15s"
  ] : var.default_args
  host_network       = try(var.host_network, false)
}