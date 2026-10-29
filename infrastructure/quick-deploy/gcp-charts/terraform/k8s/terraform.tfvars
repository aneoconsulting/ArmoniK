# Loaded automatically. The cluster comes from terraform/gcp; all the parameters: variables.tf.

# Who may reach the load balancer (ArmoniK API, GUI, Seq, Grafana: no authentication)
ingress_allowed_cidrs = ["0.0.0.0/0"]

# Chart versions and image tags: defaults in variables.tf
# versions = {
#   core = "0.41.3"
# }

# Your workers, on top of the chart's default, stream and htcmock partitions. A worker update is a new tag here
# and an apply.
# partitions = {
#   myapp = {
#     image  = "europe-west9-docker.pkg.dev/my-project/my-repo/my-worker"
#     tag    = "1.0.0"
#     cpu    = "2"
#     memory = "4Gi"
#   }
# }
