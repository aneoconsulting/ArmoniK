output "client_public_ip" {
  value = [
  for key in
  var.vm_names : {
    name = module.vm[key].id
    ip   = module.vm[key].public_ip
  }
  ]
}