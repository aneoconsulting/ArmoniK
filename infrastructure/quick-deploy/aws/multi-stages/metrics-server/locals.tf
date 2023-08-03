locals {
  # metrics server
  image = "${var.aws_account_id}.dkr.ecr.${var.region}.amazonaws.com/${var.suffix}/${var.docker_image.image}"
  default_args = try(var.args, []) == [] ? [
    "--cert-dir=/tmp",
    "--kubelet-preferred-address-types=InternalIP,ExternalIP,Hostname",
    "--kubelet-use-node-status-port",
    "--metric-resolution=15s"
  ] : var.args
}
