# Generate username
resource "random_string" "user" {
  length  = 8
  special = false
  number  = false
}

# Generate password
resource "random_password" "password" {
  length           = 16
  special          = true
  lower            = true
  upper            = true
  number           = true
  override_special = "!@#$%&*()-_=+[]{}<>:?"
}

# create file
locals {
  username = (var.user.username != "" ? var.user.username : random_string.user.result)
  password = (var.user.password != "" ? var.user.password : random_password.password.result)
  creds    = <<EOT
username: "${local.username}"
password: "${local.password}"
EOT
}

resource "null_resource" "encrypt" {
  provisioner "local-exec" {
    command = "mkdir -p ${abspath(var.directory_path)}"
  }
  provisioner "local-exec" {
    command     = "aws kms encrypt --key-id ${var.kms_key_id} --region ${var.region} --plaintext fileb://<(echo -n '${local.creds}') --output text --query CiphertextBlob > ${abspath(var.directory_path)}/${var.resource_name}-creds.yaml"
    interpreter = ["bash", "-c"]
  }
}

