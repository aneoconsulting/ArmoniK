# Update Kubeconfig
resource "null_resource" "update_kubeconfig" {
  triggers = {
    cluster_arn = module.eks.cluster_arn
  }
  provisioner "local-exec" {
    command = "aws --profile ${var.profile} eks update-kubeconfig --region ${local.region} --name ${module.eks.cluster_name}"
  }
  provisioner "local-exec" {
    when    = destroy
    command = "kubectl config delete-cluster ${self.triggers.cluster_arn}"
  }
  provisioner "local-exec" {
    when    = destroy
    command = "kubectl config unset current-context"
  }
  provisioner "local-exec" {
    when    = destroy
    command = "kubectl config delete-context ${self.triggers.cluster_arn}"
  }
}