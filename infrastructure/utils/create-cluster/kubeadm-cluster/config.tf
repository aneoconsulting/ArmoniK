/*resource "null_resource" "master" {
  depends_on = [module.master]
  provisioner "local-exec" {
    command     = "ssh -i ${var.ssh_key.private_key_path} -o \"StrictHostKeyChecking no\" ec2-user@${module.master.public_ip} 'sudo kubeadm init --apiserver-cert-extra-sans=${module.master.public_ip} --pod-network-cidr=192.168.0.0/16 ; mkdir -p $HOME/.kube ; sudo cp /etc/kubernetes/admin.conf $HOME/.kube/config ; sudo chown $(id -u):$(id -g) $HOME/.kube/config'"
    interpreter = ["/bin/bash", "-c"]
  }
}

resource "null_resource" "calico" {
  depends_on = [module.master, null_resource.master]
  provisioner "local-exec" {
    command = "ssh -i ${var.ssh_key.private_key_path} -o \"StrictHostKeyChecking no\" ec2-user@${module.master.public_ip} 'curl -s https://docs.projectcalico.org/manifests/calico.yaml > calico.yaml ; sed -i -e \"s?# - name: CALICO_IPV4POOL_CIDR?- name: CALICO_IPV4POOL_CIDR?g\" calico.yaml ; sed -i -e \"s?#   value: \"192.168.0.0/16\"?  value: \"192.168.0.0/16\"?g\" calico.yaml ; kubectl apply -f calico.yaml'"
    interpreter = ["/bin/bash", "-c"]
  }
}*/

resource "null_resource" "worker_ssh_key" {
  depends_on = [module.master, module.worker]
  count      = var.nb_workers
  provisioner "local-exec" {
    command     = "scp -i ${var.ssh_key.private_key_path} -o \"StrictHostKeyChecking no\" ${var.ssh_key.private_key_path} ec2-user@${module.worker[count.index].public_ip}:/home/ec2-user/.ssh"
    interpreter = ["/bin/bash", "-c"]
  }
}
/*
resource "null_resource" "worker" {
  depends_on = [module.master, module.worker, null_resource.master, null_resource.calico, null_resource.worker_ssh_key]
  count      = var.nb_workers
  provisioner "local-exec" {
    command     = "ssh -i ${var.ssh_key.private_key_path} -o \"StrictHostKeyChecking no\" ec2-user@${module.worker[count.index].public_ip} \"sudo kubeadm join ${module.master.public_ip}:6443 --token $(ssh -i ${var.ssh_key.private_key_path} -o \"StrictHostKeyChecking no\" ec2-user@${module.master.public_ip} 'kubeadm token list' | sed 1d | awk '{print $1}') --discovery-token-ca-cert-hash $(ssh -i ${var.ssh_key.private_key_path} -o \"StrictHostKeyChecking no\" ec2-user@${module.master.public_ip} 'openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt | openssl rsa -pubin -outform der 2>/dev/null | openssl dgst -sha256 -hex' | sed 's/^.* //')\""
    interpreter = ["/bin/bash", "-c"]
  }
}*/