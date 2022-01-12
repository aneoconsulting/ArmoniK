output "master_public_ip" {
  value = {
    name = module.master.id
    ip   = module.master.public_ip
  }
}

output "worker_public_ip" {
  value = [
  for worker in module.worker : {
    name = worker.id
    ip   = worker.public_ip
  }
  ]
}