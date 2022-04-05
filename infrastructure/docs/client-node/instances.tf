# SSH key
resource "aws_key_pair" "ssh_key" {
  key_name   = "cluster-key"
  public_key = var.ssh_key.public_key
}

resource "aws_iam_role" "client_role" {
  name               = "client-role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

# SSM managed instance core
resource "aws_iam_role_policy_attachment" "ssm_agent" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMFullAccess"
  role       = aws_iam_role.client_role.name
}

# Full access S3 bucket
resource "aws_iam_role_policy_attachment" "s3_full_access" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
  role       = aws_iam_role.client_role.name
}

resource "aws_iam_instance_profile" "client_profile" {
  name = "client-profile"
  role = aws_iam_role.client_role.name
}

# master
module "client" {
  source                      = "terraform-aws-modules/ec2-instance/aws"
  version                     = "~> 3.3.0"
  name                        = "client"
  ami                         = var.ami
  instance_type               = var.instance_type
  key_name                    = aws_key_pair.ssh_key.key_name
  monitoring                  = true
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.client_profile.name
  root_block_device           = [
    {
      volume_size = 100 # in GB <<----- I increased this!
      volume_type = "gp3"
    }
  ]
  vpc_security_group_ids      = [aws_security_group.client.id]
  #subnet_id                   = module.vpc.private_subnets[0]
  subnet_id                   = aws_default_subnet.subnet.id
  user_data_base64            = data.template_cloudinit_config.client_cloud_init.rendered
  tags                        = var.tags
  #depends_on = [module.vpc]
}
