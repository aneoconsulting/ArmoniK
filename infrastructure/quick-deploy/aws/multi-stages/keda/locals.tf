locals {
  # Keda
  image                    = "${var.aws_account_id}.dkr.ecr.${var.region}.amazonaws.com/${var.suffix}/${var.keda.docker_image.keda.image}"
  metrics_api_server_image = "${var.aws_account_id}.dkr.ecr.${var.region}.amazonaws.com/${var.suffix}/${var.keda.docker_image.metrics_api_server.image}"
}
