# S" Payloads
output "host" {
  value = local.host
}

output "port" {
  value = local.port
}

output "url" {
  value = local.url
}

output "login" {
  value = local.login
}

output "password" {
  value = local.password
}

output "must_force_path_style" {
  # needed for dns resolution on prem http://bucket.servicename:8001 vs http://servicename:8001/bucket
  value = true
}