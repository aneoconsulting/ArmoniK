# Copy images
resource "null_resource" "copy_images" {
  count      = length(var.repositories)
  triggers   = {
    state = join("-", [
      var.repositories[count.index].name, var.repositories[count.index].image, var.repositories[count.index].tag
    ])
  }

  provisioner "local-exec" {
    command = <<-EOT
      aws ecr get-login-password --region ${var.region}  | docker login --username AWS --password-stdin ${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.region}.amazonaws.com
      aws ecr-public get-login-password --region us-east-1  | docker login --username AWS --password-stdin public.ecr.aws
      if ! docker pull ${var.repositories[count.index].image}:${var.repositories[count.index].tag}
      then
        echo "cannot download image ${var.repositories[count.index].image}:${var.repositories[count.index].tag}"
        exit 1
      fi
      if ! docker tag ${var.repositories[count.index].image}:${var.repositories[count.index].tag} ${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.region}.amazonaws.com/${var.repositories[count.index].name}:${var.repositories[count.index].tag}
      then
        echo "cannot tag image ${var.repositories[count.index].image}:${var.repositories[count.index].tag} to ${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.region}.amazonaws.com/${var.repositories[count.index].name}:${var.repositories[count.index].tag}"
        exit 1
      fi
      if ! docker push ${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.region}.amazonaws.com/${var.repositories[count.index].name}:${var.repositories[count.index].tag}
      then
        echo "cannot push image ${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.region}.amazonaws.com/${var.repositories[count.index].name}:${var.repositories[count.index].tag}"
        exit 1
      fi
    EOT
  }
  depends_on = [
    aws_ecr_repository.ecr
  ]
}