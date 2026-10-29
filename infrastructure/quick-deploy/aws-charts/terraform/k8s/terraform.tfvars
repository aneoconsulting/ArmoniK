# Loaded automatically. The cluster comes from terraform/aws; all the parameters: variables.tf.

# AWS CLI profile; null uses the environment credentials
# profile = "my-sso-profile"

# Who may reach the NLB (ArmoniK API, GUI, Seq, Grafana: no authentication)
ingress_allowed_cidrs = ["0.0.0.0/0"]

# Chart versions and image tags: defaults in variables.tf
# versions = {
#   core = "0.41.3"
# }

# Your workers, on top of the chart's default, stream and htcmock partitions. A worker update is a new tag
# here and `just k8s`. image: the output workers_repository, or any repository the nodes can pull.
# partitions = {
#   myapp = {
#     image  = "<output workers_repository of terraform/aws>"
#     tag    = "myapp-1.0.0"
#     cpu    = "2"
#     memory = "4Gi"
#   }
# }

partitions = {
  # Core's Bench worker (tasks of BenchOptions__TaskDurationMs), for the PostgreSQL stress tests
  bench = {
    image        = "125796369274.dkr.ecr.eu-west-3.amazonaws.com/armonik69/docker-hub/dockerhubaneo/armonik_core_bench_test_worker"
    tag          = "0.41.3"
    cpu          = "500m"
    memory       = "512Mi"
    max_replicas = 100
  }
}

# Npgsql options in a connection string built by ESO (chart postgresql-connection). Empty: Core's own string.
# After a change, restart Core: kubectl -n armonik rollout restart deploy -l 'app.kubernetes.io/name in (control-plane,compute-plane)'
postgresql_connection_options = "No Reset On Close=true;Max Auto Prepare=100;Auto Prepare Min Usages=2"
