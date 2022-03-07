output "client_public_ip" {
  value = {
    name = module.client.id
    ip   = module.client.public_ip
  }
}