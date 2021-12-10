# SSH key
resource "aws_key_pair" "ssh_key" {
  key_name   = "k3s-key"
  public_key = var.ssh_key
}

# master
module "master" {
  source                      = "terraform-aws-modules/ec2-instance/aws"
  version                     = "~> 3.3.0"
  name                        = "master"
  ami                         = "ami-00f7e5c52c0f43726"
  instance_type               = "t3a.xlarge"
  key_name                    = aws_key_pair.ssh_key.key_name
  monitoring                  = false
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.master_sg.id]
  subnet_id                   = aws_default_subnet.master_subnet.id
  user_data_base64            = data.template_cloudinit_config.master_cloud_init.rendered
  tags                        = var.tags
}

# worker
module "worker" {
  count                       = 3
  source                      = "terraform-aws-modules/ec2-instance/aws"
  version                     = "~> 3.3.0"
  name                        = "worker-${count.index}"
  ami                         = "ami-00f7e5c52c0f43726"
  instance_type               = "t3a.xlarge"
  key_name                    = aws_key_pair.ssh_key.key_name
  monitoring                  = false
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.worker_sg.id]
  subnet_id                   = aws_default_subnet.worker_subnet.id
  user_data_base64            = data.template_cloudinit_config.worker_cloud_init.rendered
  tags                        = var.tags
}
