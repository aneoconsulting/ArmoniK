locals {
  # metrics server
  namespace          = try(var.namespace, "kube-system")
  image              = try(var.docker_image.image, "k8s.gcr.io/metrics-server/metrics-server")
  tag                = try(var.docker_image.tag, "v0.6.1")
  image_pull_secrets = try(var.image_pull_secrets, "")
  node_selector      = try(var.node_selector, {})
}