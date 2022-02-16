resource "null_resource" "master" {
  depends_on = [module.master]
  provisioner "local-exec" {
    command     = "ssh -i ${var.ssh_key.private_key_path} -o \"StrictHostKeyChecking no\" ec2-user@${module.master.public_ip} 'curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC=\"--tls-san ${module.master.public_ip} --cluster-cidr 192.168.0.0/16\" sh -s - --write-kubeconfig-mode 644 ; mkdir -p ~/.kube ; cp /etc/rancher/k3s/k3s.yaml ~/.kube/config'"
    interpreter = ["/bin/bash", "-c"]
  }
}

resource "null_resource" "worker_ssh_key" {
  depends_on = [module.master, module.worker]
  count      = var.nb_workers
  provisioner "local-exec" {
    command     = "scp -i ${var.ssh_key.private_key_path} -o \"StrictHostKeyChecking no\" ${var.ssh_key.private_key_path} ec2-user@${module.worker[count.index].public_ip}:/home/ec2-user/.ssh"
    interpreter = ["/bin/bash", "-c"]
  }
}

resource "null_resource" "worker" {
  depends_on = [module.master, module.worker, null_resource.master, null_resource.worker_ssh_key]
  count      = var.nb_workers
  provisioner "local-exec" {
    command     = "ssh -i ${var.ssh_key.private_key_path} -o \"StrictHostKeyChecking no\" ec2-user@${module.worker[count.index].public_ip} 'curl -sfL https://get.k3s.io | K3S_URL=https://${module.master.public_ip}:6443 K3S_TOKEN=$(ssh -i ${var.ssh_key.private_key_path} -o \"StrictHostKeyChecking no\" ec2-user@${module.master.public_ip} 'sudo cat /var/lib/rancher/k3s/server/node-token') sh -'"
    interpreter = ["/bin/bash", "-c"]
  }
}