# Monitoring of the bench: what sizes the agent/worker pairs, PostgreSQL and the tasks, in the chart's Grafana
# (folder Bench). Three sources:
#   - postgres_exporter -> Prometheus: engine statistics and a few custom queries (monitoring/), every 15 s
#   - Cloud Monitoring datasource: the Cloud SQL instance itself (CPU, memory, disk, connections)
#   - PostgreSQL datasource: task-level SQL on the tables of Core, run only when a dashboard is displayed
# Every query runs as the read-only monitoring user of the database module.

locals {
  monitoring = {
    # Grafana datasource uids, referenced by the dashboards
    prometheus_uid       = "PBFA97CFB590B2093" # the chart's datasource (charts/armonik grafana-datasource-armonik)
    cloud_monitoring_uid = "cloud-monitoring"
    postgresql_uid       = "armonik-postgresql"
    exporter_name        = "postgres-exporter"
  }
}

# Cloud Monitoring datasource: Grafana reads the metrics as its Kubernetes service account, through Workload Identity
module "grafana_identity" {
  source = "git::https://github.com/aneoconsulting/ArmoniK.Infra.git//service-account/gcp?ref=dw/gcp-charts-deploy"

  name                   = "armonik-grafana" # created by the grafana dependency of the armonik chart
  kubernetes_namespace   = local.namespaces.armonik
  roles                  = ["roles/monitoring.viewer"]
  create_service_account = false
  iam_service_account    = false
}

resource "kubernetes_secret_v1" "postgresql_monitoring" {
  metadata {
    name      = "postgresql-monitoring"
    namespace = kubernetes_namespace_v1.armonik.metadata[0].name
  }

  data = {
    username = module.database.monitoring_username
    password = module.database.monitoring_password
  }
}

resource "kubernetes_config_map_v1" "postgres_exporter_queries" {
  metadata {
    name      = "${local.monitoring.exporter_name}-queries"
    namespace = kubernetes_namespace_v1.armonik.metadata[0].name
  }

  data = {
    "queries.yaml" = file("${path.module}/monitoring/postgres-exporter-queries.yaml")
  }
}

resource "helm_release" "postgres_exporter" {
  name       = local.monitoring.exporter_name
  namespace  = kubernetes_namespace_v1.armonik.metadata[0].name
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "prometheus-postgres-exporter"
  version    = "8.2.4"

  values = [yamlencode({
    fullnameOverride = local.monitoring.exporter_name
    image = {
      registry   = module.registry.urls.quay
      repository = "prometheuscommunity/postgres-exporter"
    }
    config = {
      datasource = {
        host     = module.database.host
        port     = tostring(module.database.port)
        database = module.database.database
        user     = module.database.monitoring_username
        passwordSecret = {
          name = kubernetes_secret_v1.postgresql_monitoring.metadata[0].name
          key  = "password"
        }
        # The server certificate is verified against the CA of the instance, host name included
        sslmode     = "verify-full"
        extraParams = "sslrootcert=/ca/ca.crt&application_name=postgres_exporter"
      }
      extraArgs = [
        "--extend.query-path=/queries/queries.yaml",
        "--collector.stat_statements",
        "--collector.stat_statements.include_query",
        "--collector.stat_statements.query_length=200",
        "--collector.stat_statements.limit=50",
        "--collector.stat_activity",
        "--collector.stat_activity_autovacuum",
        "--collector.stat_checkpointer",
        "--collector.long_running_transactions",
        "--collector.statio_user_indexes",
      ]
    }
    extraVolumes = [
      { name = "ca", secret = { secretName = kubernetes_secret_v1.postgresql_ca.metadata[0].name } },
      { name = "queries", configMap = { name = kubernetes_config_map_v1.postgres_exporter_queries.metadata[0].name } },
    ]
    extraVolumeMounts = [
      { name = "ca", mountPath = "/ca", readOnly = true },
      { name = "queries", mountPath = "/queries", readOnly = true },
    ]
    serviceMonitor = {
      enabled  = true
      interval = "15s"
    }
    resources = {
      requests = { cpu = "50m", memory = "64Mi" }
      limits   = { memory = "256Mi" }
    }
  })]

  # The ServiceMonitor CRD comes with the operators
  depends_on = [helm_release.armonik_operators]
}

# Datasources, as a Secret: the sidecar of the chart's Grafana loads the ones labelled grafana_datasource
resource "kubernetes_secret_v1" "grafana_datasources" {
  metadata {
    name      = "grafana-datasources-bench"
    namespace = kubernetes_namespace_v1.armonik.metadata[0].name
    labels    = { grafana_datasource = "1" }
  }

  data = {
    "bench.yaml" = yamlencode({
      apiVersion = 1
      datasources = [
        {
          name     = "Cloud Monitoring"
          type     = "stackdriver"
          uid      = local.monitoring.cloud_monitoring_uid
          access   = "proxy"
          jsonData = { authenticationType = "gce", defaultProject = var.project }
        },
        {
          name   = "ArmoniK PostgreSQL"
          type   = "grafana-postgresql-datasource"
          uid    = local.monitoring.postgresql_uid
          access = "proxy"
          url    = "${module.database.host}:${module.database.port}"
          user   = module.database.monitoring_username
          jsonData = {
            database               = module.database.database
            sslmode                = "verify-full"
            tlsConfigurationMethod = "file-content"
            postgresVersion        = 1800
            maxOpenConns           = 4
            maxIdleConns           = 2
          }
          secureJsonData = {
            password  = module.database.monitoring_password
            tlsCACert = module.database.ca_cert
          }
        },
      ]
    })
  }
}

# Dashboards: Grafana JSON in monitoring/dashboards, the GCP placeholders replaced here. The autoscaling one reads the
# rules of autoscaling.tf: not without them.
resource "kubernetes_config_map_v1" "grafana_dashboards" {
  for_each = setsubtract(
    fileset("${path.module}/monitoring/dashboards", "*.json"),
    var.autoscaling_laws ? [] : ["bench-autoscaling.json"],
  )

  metadata {
    name        = "grafana-dashboard-${trimsuffix(each.value, ".json")}"
    namespace   = kubernetes_namespace_v1.armonik.metadata[0].name
    labels      = { grafana_dashboard = "1" }
    annotations = { grafana_dashboard_folder = "Bench" }
  }

  data = {
    (each.value) = replace(replace(replace(replace(
      file("${path.module}/monitoring/dashboards/${each.value}"),
      "__CLOUDSQL_DATABASE_ID__", "${var.project}:${module.database.name}"),
      "__PROJECT__", var.project),
      "__PUBSUB_PREFIX__", var.prefix),
      "__BUCKET__", module.object_storage.name
    )
  }
}

# Per-container series of the compute plane, aggregated once: the dashboards stay fast with thousands of pods
resource "kubectl_manifest" "bench_recording_rules" {
  yaml_body = yamlencode({
    apiVersion = "monitoring.coreos.com/v1"
    kind       = "PrometheusRule"
    metadata = {
      name      = "armonik-bench"
      namespace = local.namespaces.operators
      # The ruleSelector of the operators' Prometheus
      labels = { release = "armonik-operators" }
    }
    spec = {
      groups = [{
        name     = "armonik-bench"
        interval = "15s"
        rules = [
          {
            record = "armonik:container_cpu_millicores:rate1m"
            expr   = <<-EOT
              label_replace(
                1000 * sum by (pod, container) (rate(container_cpu_usage_seconds_total{namespace="armonik",container=~"agent|worker",pod=~"armonik-compute-plane-.+"}[1m])),
                "partition", "$1", "pod", "armonik-compute-plane-(.+)-[a-z0-9]+-[a-z0-9]+")
            EOT
          },
          {
            record = "armonik:container_memory_working_set_mib"
            expr   = <<-EOT
              label_replace(
                sum by (pod, container) (container_memory_working_set_bytes{namespace="armonik",container=~"agent|worker",pod=~"armonik-compute-plane-.+"}) / 1048576,
                "partition", "$1", "pod", "armonik-compute-plane-(.+)-[a-z0-9]+-[a-z0-9]+")
            EOT
          },
          {
            record = "armonik:container_cpu_throttled_ratio:rate1m"
            expr   = <<-EOT
              label_replace(
                sum by (pod, container) (rate(container_cpu_cfs_throttled_periods_total{namespace="armonik",container=~"agent|worker",pod=~"armonik-compute-plane-.+"}[1m]))
                / sum by (pod, container) (rate(container_cpu_cfs_periods_total{namespace="armonik",container=~"agent|worker",pod=~"armonik-compute-plane-.+"}[1m])),
                "partition", "$1", "pod", "armonik-compute-plane-(.+)-[a-z0-9]+-[a-z0-9]+")
            EOT
          },
          {
            # All partitions: Core records the end of a task with one statement, without the partition
            record = "armonik:tasks_ended:rate1m"
            expr   = "sum(rate(pg_armonik_task_ends_calls[1m]))"
          },
        ]
      }]
    }
  })

  depends_on = [helm_release.armonik_operators]
}
