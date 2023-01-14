# S" Payloads
output "host" {
  value = var.minioconfig.host
}

output "port" {
  value = var.minioconfig.port
}

output "url" {
  value = "http://${var.minioconfig.host}:${var.minioconfig.port}"
}

output "login" {
  value = var.minioconfig.login
}

output "password" {
  value = var.minioconfig.password
}

output "bucket_name" {
  value = var.minioconfig.bucket_name
}

output "must_force_path_style" {
  # needed for dns resolution on prem http://bucket.servicename:8001 vs http://servicename:8001/bucket
  value = true
}