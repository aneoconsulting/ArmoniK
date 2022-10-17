# Render the cloud config for master
data "template_cloudinit_config" "client_cloud_init" {
  for_each      = toset(var.vm_names)
  gzip          = true
  base64_encode = true

  part {
    filename   = "0000-packages.yml"
    content    = templatefile("cloud-init-templates/0000-packages.yaml", {})
    merge_type = var.extra_userdata_merge
  }
  part {
    filename   = "0001-ssmmanager.yml"
    content    = templatefile("cloud-init-templates/0001-ssmmanager.yaml", { region = var.region })
    merge_type = var.extra_userdata_merge
  }
  part {
    filename   = "0002-awscli2.yml"
    content    = templatefile("cloud-init-templates/0002-awscli2.yaml", {})
    merge_type = var.extra_userdata_merge
  }
  part {
    filename   = "0003-dokcer.yml"
    content    = templatefile("cloud-init-templates/0003-docker.yaml", {})
    merge_type = var.extra_userdata_merge
  }
  part {
    filename   = "0004-kubectl.yml"
    content    = templatefile("cloud-init-templates/0004-kubectl.yaml", {})
    merge_type = var.extra_userdata_merge
  }
  part {
    filename   = "0005-helm.yml"
    content    = templatefile("cloud-init-templates/0005-helm.yaml", {})
    merge_type = var.extra_userdata_merge
  }
  part {
    filename   = "0006-terraform.yml"
    content    = templatefile("cloud-init-templates/0006-terraform.yaml", {})
    merge_type = var.extra_userdata_merge
  }
  part {
    filename   = "0007-ssh.yml"
    content    = templatefile("cloud-init-templates/0007-ssh.yaml", {})
    merge_type = var.extra_userdata_merge
  }
  part {
    filename   = "0008-dotnet.yml"
    content    = templatefile("cloud-init-templates/0008-dotnet.yaml", {})
    merge_type = var.extra_userdata_merge
  }
  part {
    filename   = "0009-k3s.yml"
    content    = templatefile("cloud-init-templates/0009-k3s.yaml", {})
    merge_type = var.extra_userdata_merge
  }
  part {
    filename   = "0010-armonik.yml"
    content    = templatefile("cloud-init-templates/0010-armonik.yaml", {})
    merge_type = var.extra_userdata_merge
  }
  part {
    filename   = "0011-python3.yml"
    content    = templatefile("cloud-init-templates/0011-python3.yaml", {})
    merge_type = var.extra_userdata_merge
  }
  part {
    filename   = "0012-fsinotify.yml"
    content    = templatefile("cloud-init-templates/0012-fsinotify.yaml", {})
    merge_type = var.extra_userdata_merge
  }
  /*part {
    filename   = "0013-copyfile.yml"
    content    = templatefile("cloud-init-templates/0013-copyfile.yaml", {
      content = filebase64("${path.root}/data/kubectl-cheat-sheet.md")
    })
    merge_type = var.extra_userdata_merge
  }
  part {
    filename   = "0014-hostname.yml"
    content    = templatefile("cloud-init-templates/0014-hostname.yaml", {
      name = each.key
    })
    merge_type = var.extra_userdata_merge
  }*/
}