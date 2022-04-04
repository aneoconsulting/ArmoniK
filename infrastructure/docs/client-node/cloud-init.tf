# Render the cloud config for master
data "template_cloudinit_config" "client_cloud_init" {
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
    filename   = "0009-python3.yml"
    content    = templatefile("cloud-init-templates/0009-python3.yaml", {})
    merge_type = var.extra_userdata_merge
  }
  part {
    filename   = "0010-armonik.yml"
    content    = templatefile("cloud-init-templates/0010-armonik.yaml", {})
    merge_type = var.extra_userdata_merge
  }
}