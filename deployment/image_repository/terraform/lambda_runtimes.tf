resource null_resource "build_dotnet50" {
  triggers = {
    always_run = timestamp()
  }
  provisioner "local-exec" {
    command = "docker build -t ${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.region}.amazonaws.com/lambda:5.0.2 -f ./lambda_runtimes/Dockerfile.dotnet5.0 ./lambda_runtimes"
  }
  depends_on = [
    null_resource.authenticate_to_ecr_repository
  ]
}

resource null_resource "push_dotnet50" {
  triggers = {
    always_run = timestamp()
  }
  provisioner "local-exec" {
    command = "docker push ${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.region}.amazonaws.com/lambda:5.0.2"
  }
  depends_on = [
    null_resource.authenticate_to_ecr_repository,
    null_resource.build_dotnet50
  ]
}
