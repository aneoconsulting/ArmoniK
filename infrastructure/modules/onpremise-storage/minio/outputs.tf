output "host" {
  value = var.minio.host
}

output "port" {
  value = local.port
}

output "url" {
  value = "http://${var.minio.host}:${local.port}"
}

output "console_url" {
  value = "http://${var.minio.host}:${local.console_port}"
}

output "login" {
  value     = random_string.minio_application_user.result
  sensitive = true
}

output "password" {
  value     = random_password.minio_application_password.result
  sensitive = true
}

output "bucket_name" {
  value = var.minio.bucket_name
}

output "must_force_path_style" {
  # needed for dns resolution on prem http://bucket.servicename:8001 vs http://servicename:8001/bucket
  value = true
}