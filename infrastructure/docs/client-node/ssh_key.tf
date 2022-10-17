resource "tls_private_key" "rsa" {
  for_each  = toset(var.vm_names)
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "generated_key" {
  for_each   = toset(var.vm_names)
  key_name   = each.key
  public_key = tls_private_key.rsa[each.key].public_key_openssh
}

resource "local_sensitive_file" "ingress_client_key" {
  for_each        = toset(var.vm_names)
  content         = tls_private_key.rsa[each.key].private_key_pem
  filename        = "${path.root}/generated/ssh-keys/${each.key}.pem"
  file_permission = "0600"
}