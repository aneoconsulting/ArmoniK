# terraform/aws of the stack montparnasse (-var-file): ArmoniK for the MontparnasseAgent demo (PymoniK workers),
# beside armonik69 in the same account. All the parameters: terraform/aws/variables.tf.
# Helm releases, partitions and NLB access: k8s.tfvars

# Name of every resource (cluster, RDS, bucket, ECR...)
prefix = "montparnasse"
# Ohio, the closest region to Chicago (SC26); the state stays in the eu-west-3 bucket
region = "us-east-2"
# AWS CLI profile; null uses the environment credentials
# profile = "my-sso-profile"

tags = {
  "origin"  = "terraform"
  "csp"     = "aws"
  "project" = "montparnasse-agent"
}

vpc = {
  single_nat_gateway = true
  flow_logs          = false
}

eks = {
  kubernetes_version = "1.35"
}
