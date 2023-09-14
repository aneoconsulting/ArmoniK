
locals {
  admin_gui_image                   = "${var.aws_account_id}.dkr.ecr.${var.region}.amazonaws.com/${var.suffix}/${var.admin_gui.image}"
  admin_0_9_gui_image               = "${var.aws_account_id}.dkr.ecr.${var.region}.amazonaws.com/${var.suffix}/${var.admin_0_9_gui.image}"
  job_partitions_in_database_image  = "${var.aws_account_id}.dkr.ecr.${var.region}.amazonaws.com/${var.suffix}/${var.job_partitions_in_database.image}"
  control_plane_image               = "${var.aws_account_id}.dkr.ecr.${var.region}.amazonaws.com/${var.suffix}/${var.control_plane.image}"
  admin_0_8_gui_api_image           = "${var.aws_account_id}.dkr.ecr.${var.region}.amazonaws.com/${var.suffix}/${var.admin_0_8_gui.api.image}"
  admin_0_8_gui_app_image           = "${var.aws_account_id}.dkr.ecr.${var.region}.amazonaws.com/${var.suffix}/${var.admin_0_8_gui.app.image}"
  ingress_image                     = "${var.aws_account_id}.dkr.ecr.${var.region}.amazonaws.com/${var.suffix}/${var.ingress.image}"
  authentication_image              = "${var.aws_account_id}.dkr.ecr.${var.region}.amazonaws.com/${var.suffix}/${var.authentication.image}"
  compute_plane_polling_agent_image = "${var.aws_account_id}.dkr.ecr.${var.region}.amazonaws.com/${var.suffix}/${var.compute_plane.default.polling_agent.image}"
  compute_plane_worker_images       = { for key, value in var.compute_plane : key => [for w in value.worker : "${var.aws_account_id}.dkr.ecr.${var.region}.amazonaws.com/${var.suffix}/${w.image}"] }
}