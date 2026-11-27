# Stack armonik69 (-var-file). All the parameters: variables.tf.

# Name of every resource (cluster, database, bucket, ECR...)
prefix = "armonik69"
region = "eu-west-3"
# AWS CLI profile; null uses the environment credentials
# profile = "my-sso-profile"

tags = {
  "origin" = "terraform"
  "csp"    = "aws"
}

# Who may reach the NLB (ArmoniK API, GUI, Seq, Grafana: no authentication)
ingress_allowed_cidrs = ["0.0.0.0/0"]

# Aurora PostgreSQL. Provisioned bench sizes (instance_class, without serverless): db.r8g.4xlarge (16 vCPUs, the
# Cloud SQL N-16 of the GCP bench), db.r8g.2xlarge (8), db.r8g.8xlarge (32). Serverless v2: 64 ACUs = 128 GiB, the
# memory of a db.r8g.4xlarge. io_optimized: AWS limits how often a cluster switches to it.
database = {
  serverless = {
    min_capacity = 0.5
    max_capacity = 64
  }
  io_optimized = true
  proxy = {
    enabled = true
  }
}

# Object storage of Core on S3 Express One Zone (euw3-az1, the only zone offering it in Paris). pin_to_express_zone
# keeps the Karpenter nodes in that zone too.
object_storage = {
  express             = true
  express_zone_id     = "euw3-az1"
  pin_to_express_zone = false
}

# Your workers, beside the chart's htcmock. A worker update is a new tag here. image: the output workers_repository,
# or any repository the nodes can pull.
# partitions = {
#   myapp = {
#     image = "<output workers_repository>"
#     tag   = "myapp-1.0.0"
#   }
# }

# Sizing of the stack, merged last over values/armonik.yaml
# armonik_values = [<<-EOT
#   control-plane:
#     replicas: 3
#   EOT
# ]
