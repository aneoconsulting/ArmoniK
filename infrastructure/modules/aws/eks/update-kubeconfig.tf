# Update Kubeconfig
resource "null_resource" "update_kubeconfig" {
  triggers = {
    cluster_arn = module.eks.cluster_arn
  }
  provisioner "local-exec" {
    command = "aws --profile ${var.profile} eks update-kubeconfig --region ${local.region} --name ${module.eks.cluster_name} --kubeconfig ${local.kubeconfig_output_path}"
  }
}