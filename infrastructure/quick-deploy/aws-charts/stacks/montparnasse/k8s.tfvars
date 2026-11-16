# terraform/k8s of the stack montparnasse (-var-file). The cluster comes from terraform/aws; all the parameters:
# terraform/k8s/variables.tf.

# AWS CLI profile; null uses the environment credentials
# profile = "my-sso-profile"

# Who may reach the NLB (ArmoniK API, GUI, Seq, Grafana: no authentication). To fill in: empty fails the plan.
ingress_allowed_cidrs = ["0.0.0.0/0"]

# PymoniK workers (MontparnasseAgent deploy/images, flavour cpu), built for amd64 (the node pools are amd64 only)
# and pushed to the output workers_repository of terraform/aws before this apply. Partition cpu: the name the
# agent's programs use. 2Gi for the scene libraries (sdf, trimesh); 8 pods kept running, so a visitor's first run
# does not wait for a pod and a node.
partitions = {
  cpu = {
    image        = "125796369274.dkr.ecr.us-east-2.amazonaws.com/montparnasse/workers"
    tag          = "cpu-0.1.0"
    cpu          = "1"
    memory       = "2Gi"
    min_replicas = 8
    max_replicas = 48
  }
}

postgresql_connection_options = "No Reset On Close=true;Max Auto Prepare=100;Auto Prepare Min Usages=2;Connection Idle Lifetime=30"
