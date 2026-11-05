# Loaded automatically. The cluster comes from terraform/aws; all the parameters: variables.tf.

# AWS CLI profile; null uses the environment credentials
# profile = "my-sso-profile"

# Who may reach the NLB (ArmoniK API, GUI, Seq, Grafana: no authentication)
ingress_allowed_cidrs = ["0.0.0.0/0"]

# Chart versions and image tags: defaults in variables.tf
# versions = {
#   core = "0.41.3"
# }

# Your workers, the only partitions (the chart's default, stream and htcmock are removed in values/armonik.yaml).
# A worker update is a new tag here and `just k8s`. image: the output workers_repository, or any repository the nodes can pull.
# partitions = {
#   myapp = {
#     image  = "<output workers_repository of terraform/aws>"
#     tag    = "myapp-1.0.0"
#     cpu    = "2"
#     memory = "4Gi"
#   }
# }

partitions = {
  # QuantLib pricing worker (ArmoniK.Samples python/quantlib): one task at a time on one Python thread, so one
  # CPU; QuantLib keeps no paths or grids in memory (Monte Carlo accumulates statistics only)
  quantlib = {
    image        = "125796369274.dkr.ecr.eu-west-3.amazonaws.com/armonik69/workers/armonik_quantlib_worker"
    tag          = "0.2.1"
    cpu          = "1"
    memory       = "512Mi"
    max_replicas = 20
  }
  # supprimer toute les partitions par default et ne garder que quantlib + clean la db

  # Core test workers, through the Docker Hub pull-through cache (tag = Core version), for the autoscaling bench
  # (bench/README.md). Bench: tasks of a fixed duration; HtcMock: a tree of subtasks created by the workers.
  bench = {
    image        = "125796369274.dkr.ecr.eu-west-3.amazonaws.com/armonik69/docker-hub/dockerhubaneo/armonik_core_bench_test_worker"
    tag          = "0.41.3"
    max_replicas = 100
    fast_hpa     = true
  }
  # A/B of the autoscaling target (bench/bench.py suite): twin partitions per workload, same worker,
  # b = queued / 2 (Core's metric), p = the flow model in PromQL (armonik:scaler_target).
  # One workload per partition: each keeps its own task duration.
  short200b = {
    image        = "125796369274.dkr.ecr.eu-west-3.amazonaws.com/armonik69/docker-hub/dockerhubaneo/armonik_core_bench_test_worker"
    tag          = "0.41.3"
    max_replicas = 100
    fast_hpa     = true
  }
  short200p = {
    image        = "125796369274.dkr.ecr.eu-west-3.amazonaws.com/armonik69/docker-hub/dockerhubaneo/armonik_core_bench_test_worker"
    tag          = "0.41.3"
    max_replicas = 100
    promql       = true
    fast_hpa     = true
  }
  short1sb = {
    image        = "125796369274.dkr.ecr.eu-west-3.amazonaws.com/armonik69/docker-hub/dockerhubaneo/armonik_core_bench_test_worker"
    tag          = "0.41.3"
    max_replicas = 100
    fast_hpa     = true
  }
  short1sp = {
    image        = "125796369274.dkr.ecr.eu-west-3.amazonaws.com/armonik69/docker-hub/dockerhubaneo/armonik_core_bench_test_worker"
    tag          = "0.41.3"
    max_replicas = 100
    promql       = true
    fast_hpa     = true
  }
  htcmockb = {
    image        = "125796369274.dkr.ecr.eu-west-3.amazonaws.com/armonik69/docker-hub/dockerhubaneo/armonik_core_htcmock_test_worker"
    tag          = "0.41.3"
    max_replicas = 100
    fast_hpa     = true
  }
  htcmockp = {
    image        = "125796369274.dkr.ecr.eu-west-3.amazonaws.com/armonik69/docker-hub/dockerhubaneo/armonik_core_htcmock_test_worker"
    tag          = "0.41.3"
    max_replicas = 100
    promql       = true
    fast_hpa     = true
  }
  # Long tasks (minutes): the running tasks must keep their pods at the end of a batch, and a waiting task asks at
  # most one pod (bench.py s16-long)
  longb = {
    image        = "125796369274.dkr.ecr.eu-west-3.amazonaws.com/armonik69/docker-hub/dockerhubaneo/armonik_core_bench_test_worker"
    tag          = "0.41.3"
    max_replicas = 100
    fast_hpa     = true
  }
  longp = {
    image        = "125796369274.dkr.ecr.eu-west-3.amazonaws.com/armonik69/docker-hub/dockerhubaneo/armonik_core_bench_test_worker"
    tag          = "0.41.3"
    max_replicas = 100
    promql       = true
    fast_hpa     = true
  }
}

# Npgsql options in a connection string built by ESO (chart postgresql-connection). Empty: Core's own string.
# After a change, restart Core: kubectl -n armonik rollout restart deploy -l 'app.kubernetes.io/name in (control-plane,compute-plane)'
# Connection Idle Lifetime: idle connections closed after 30 s instead of 300, so a burst does not hold the
# RDS connections for 5 min. Pool size: PostgreSQL__MaxPoolSize in values/armonik.yaml (Core overrides it here)
postgresql_connection_options = "No Reset On Close=true;Max Auto Prepare=100;Auto Prepare Min Usages=2;Connection Idle Lifetime=30"
