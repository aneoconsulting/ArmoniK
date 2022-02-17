output "master_public_ip" {
  value = {
    name       = module.master.id
    public_ip  = module.master.public_ip
    private_ip = module.master.private_ip
  }
}

output "worker_public_ip" {
  value = [
  for worker in module.worker : {
    name       = worker.id
    public_ip  = worker.public_ip
    private_ip = worker.private_ip
  }
  ]
}