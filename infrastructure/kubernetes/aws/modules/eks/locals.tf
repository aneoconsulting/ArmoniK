locals {
  workers_userdata = <<-EOT
sudo yum update -y
sudo amazon-linux-extras install -y epel
sudo yum install -y s3fs-fuse
sudo mkdir -p /data
sudo s3fs ${var.eks.shared_storage} /data -o iam_role="auto"
sudo echo "${var.eks.shared_storage} /data fuse.s3fs _netdev,allow_other 0 0" >> /etc/fstab
EOT
}