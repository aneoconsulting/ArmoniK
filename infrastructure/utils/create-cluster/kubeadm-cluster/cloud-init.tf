# Render the cloud config for master
data "template_cloudinit_config" "master_cloud_init" {
  gzip          = true
  base64_encode = true

  part {
    filename   = "0000-dokcer.yml"
    content    = templatefile("cloud-init-templates/0000-docker.yaml", {})
    merge_type = var.extra_userdata_merge
  }

  part {
    filename   = "0001-kubectl.yml"
    content    = templatefile("cloud-init-templates/0001-kubectl.yaml", {})
    merge_type = var.extra_userdata_merge
  }

  part {
    filename   = "0002-nfs-master.yml"
    content    = templatefile("cloud-init-templates/0002-nfs-master.yaml", {
      worker_subnet = data.aws_subnet.worker_subnet.cidr_block
    })
    merge_type = var.extra_userdata_merge
  }

  part {
    filename   = "0003-ssh.yml"
    content    = templatefile("cloud-init-templates/0003-ssh.yaml", {})
    merge_type = var.extra_userdata_merge
  }

  part {
    filename   = "0004-kubeadm.yml"
    content    = templatefile("cloud-init-templates/0004-kubeadm.yaml", {})
    merge_type = var.extra_userdata_merge
  }
}

# Render the cloud config for worker
data "template_cloudinit_config" "worker_cloud_init" {
  gzip          = true
  base64_encode = true

  part {
    filename   = "0000-dokcer.yml"
    content    = templatefile("cloud-init-templates/0000-docker.yaml", {})
    merge_type = var.extra_userdata_merge
  }

  part {
    filename   = "0003-ssh.yml"
    content    = templatefile("cloud-init-templates/0003-ssh.yaml", {})
    merge_type = var.extra_userdata_merge
  }

  part {
    filename   = "0004-kubeadm.yml"
    content    = templatefile("cloud-init-templates/0004-kubeadm.yaml", {})
    merge_type = var.extra_userdata_merge
  }
}