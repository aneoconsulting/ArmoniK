# create ECR repositories
resource "aws_ecr_repository" "ecr" {
  count = length(var.repositories)
  name  = var.repositories[count.index].name
  image_scanning_configuration {
    scan_on_push = true
  }
  encryption_configuration {
    encryption_type = "KMS"
    kms_key         = var.kms_key_id
  }
  tags = local.tags
}

# Copy images
resource "null_resource" "copy_images" {
  count = length(var.repositories)
  triggers = {
    state = join("-", [
      var.repositories[count.index].name, var.repositories[count.index].image, var.repositories[count.index].tag
    ])
  }
  provisioner "local-exec" {
    command = <<-EOT
      aws ecr get-login-password --region ${local.region}  | docker login --username AWS --password-stdin ${data.aws_caller_identity.current.account_id}.dkr.ecr.${local.region}.amazonaws.com
      aws ecr-public get-login-password --region us-east-1  | docker login --username AWS --password-stdin public.ecr.aws
      if ! docker pull ${var.repositories[count.index].image}:${var.repositories[count.index].tag}
      then
        echo "cannot download image ${var.repositories[count.index].image}:${var.repositories[count.index].tag}"
        exit 1
      fi
      if ! docker tag ${var.repositories[count.index].image}:${var.repositories[count.index].tag} ${data.aws_caller_identity.current.account_id}.dkr.ecr.${local.region}.amazonaws.com/${var.repositories[count.index].name}:${var.repositories[count.index].tag}
      then
        echo "cannot tag image ${var.repositories[count.index].image}:${var.repositories[count.index].tag} to ${data.aws_caller_identity.current.account_id}.dkr.ecr.${local.region}.amazonaws.com/${var.repositories[count.index].name}:${var.repositories[count.index].tag}"
        exit 1
      fi
      if ! docker push ${data.aws_caller_identity.current.account_id}.dkr.ecr.${local.region}.amazonaws.com/${var.repositories[count.index].name}:${var.repositories[count.index].tag}
      then
        echo "cannot push image ${data.aws_caller_identity.current.account_id}.dkr.ecr.${local.region}.amazonaws.com/${var.repositories[count.index].name}:${var.repositories[count.index].tag}"
        exit 1
      fi
    EOT
  }
  depends_on = [
    aws_ecr_repository.ecr
  ]
}
