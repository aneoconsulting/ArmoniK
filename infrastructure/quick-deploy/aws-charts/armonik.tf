# What the ArmoniK releases need before they start: the Karpenter node pools (their pods are pending otherwise), the
# load balancer controller (its webhook mutates every Service, and rejects them until it runs), metrics-server (the
# cpu triggers of the control planes) and the Pod Identity associations of the planes and of Grafana (credentials are
# injected at pod creation only). The two namespaces are read from here, so the releases wait for them, and on
# destroy they go first.
resource "terraform_data" "platform" {
  input = {
    namespace                = var.namespace
    operators_namespace      = var.operators_namespace
    node_pools               = keys(module.karpenter.node_pools)
    load_balancer_controller = helm_release.aws_load_balancer_controller.status
    metrics_server           = helm_release.metrics_server.status
    cilium                   = module.cilium.status
    pod_identity_associations = concat(
      [for identity in module.armonik_identity : identity.pod_identity_association_id],
      [for identity in module.grafana_identity : identity.pod_identity_association_id],
    )
  }
}

# Created here rather than by Helm: the PostgreSQL Secrets go in it. On destroy, its deletion waits for the finalizer
# of the ingress Service, so the load balancer controller still runs to delete the NLB.
resource "kubernetes_namespace_v1" "armonik" {
  metadata {
    name = terraform_data.platform.output.namespace
  }
}

# Read by ESO through the SecretStore of the release (dependencies.externalPostgresql of values/armonik.yaml)
resource "kubernetes_secret_v1" "postgresql" {
  metadata {
    name      = "armonik-postgresql"
    namespace = kubernetes_namespace_v1.armonik.metadata[0].name
  }
  data = {
    username = module.database.username
    password = module.database.password
  }
}

resource "kubernetes_secret_v1" "postgresql_ca" {
  metadata {
    name      = "armonik-postgresql-ca"
    namespace = kubernetes_namespace_v1.armonik.metadata[0].name
  }
  data = {
    # The CAs of the cluster and of the RDS Proxy
    ca = module.database.ca_cert
  }
}

locals {
  values_dir = "${path.module}/values"

  values = {
    REG_DOCKERHUB         = local.registries.dockerHub
    REG_GHCR              = local.registries.ghcr
    REG_QUAY              = local.registries.quay
    REG_K8S               = local.registries.k8s
    AWS_REGION            = var.region
    PG_HOST               = module.database.host
    PG_PORT               = module.database.port
    PG_POOLER_HOST        = module.database.pooler_host == null ? "" : module.database.pooler_host
    PG_DATABASE           = module.database.database
    PG_SECRET             = kubernetes_secret_v1.postgresql.metadata[0].name
    PG_CA_SECRET          = kubernetes_secret_v1.postgresql_ca.metadata[0].name
    SQS_PREFIX            = local.sqs_prefix
    S3_BUCKET             = local.object_storage.bucket
    S3_ENDPOINT           = local.object_storage.endpoint
    INGRESS_SOURCE_RANGES = join(",", var.ingress_allowed_cidrs)
  }

  # The partitions on the workers node pool. do-not-disrupt keeps Karpenter from evicting a running task.
  workers_placement = {
    compute-plane = {
      partitionCommon = {
        nodeSelector   = module.karpenter.node_pools.workers.node_selector
        tolerations    = module.karpenter.node_pools.workers.tolerations
        podAnnotations = { "karpenter.sh/do-not-disrupt" = "true" }
      }
    }
  }

  # promql = true: trigger on armonik:scaler_target, computed by the recording rules of the autoscaling-monitoring
  # release (rules/autoscaling.rules.yaml), 1 per pod. Prometheus is in the scaling path: an empty answer (rules not
  # loaded yet, exporter or Prometheus down) is an error, not 0, so that KEDA keeps the fleet instead of scaling down.
  promql_partitions = {
    compute-plane = {
      partitions = {
        for name, p in var.partitions : name => {
          hpa = {
            fallback = { failureThreshold = 3, replicas = 1, behavior = "currentReplicasIfHigher" }
            triggers = [{
              type = "prometheus"
              metadata = {
                serverAddress       = "{{ include \"armonik.monitoring.prometheusUrl\" . }}"
                query               = "armonik:scaler_target{partition=\"${name}\"}"
                threshold           = "1"
                activationThreshold = "0"
                ignoreNullValues    = "false"
              }
            }]
          }
        } if p.promql
      }
    }
  }

  # fast_hpa = true: the HPA applies the target without its own rate limits, and keeps an idle pod about one pod
  # start (~60 s) before removing it, instead of the chart's 300 s
  fast_hpa_partitions = {
    compute-plane = {
      partitions = {
        for name, p in var.partitions : name => {
          hpa = {
            pollingInterval = 5
            cooldownPeriod  = 60
            advanced = {
              horizontalPodAutoscalerConfig = {
                behavior = {
                  scaleUp = {
                    stabilizationWindowSeconds = 0
                    selectPolicy               = "Max"
                    # Percent alone starts from the current count: 1 -> 11 -> 100 waits a period; Pods adds 100 at once
                    policies = [{ type = "Percent", value = 1000, periodSeconds = 15 }, { type = "Pods", value = 100, periodSeconds = 15 }]
                  }
                  scaleDown = {
                    stabilizationWindowSeconds = 60
                    policies                   = [{ type = "Percent", value = 100, periodSeconds = 15 }]
                  }
                }
              }
            }
          }
        } if p.fast_hpa
      }
    }
  }
}

module "armonik" {
  source = "git::https://github.com/aneoconsulting/ArmoniK.Infra.git//armonik-charts?ref=dw/armonik-charts"

  namespace           = kubernetes_namespace_v1.armonik.metadata[0].name
  operators_namespace = terraform_data.platform.output.operators_namespace
  chart_version       = var.versions.armonik
  versions = {
    core = var.versions.core
    gui  = var.versions.gui
  }

  # PostgreSQL is Aurora and MongoDB is not used
  database_operators = {
    mongodb    = false
    postgresql = false
  }
  registries = {
    dockerhub = local.registries.dockerHub
    ghcr      = local.registries.ghcr
    quay      = local.registries.quay
    k8s       = local.registries.k8s
  }
  service_accounts = local.service_accounts

  partitions = {
    for name, p in var.partitions : name => {
      image         = p.image
      tag           = p.tag
      cpu           = p.cpu
      cpu_limit     = p.cpu_limit
      memory        = p.memory
      max_replicas  = p.max_replicas
      scale_to_zero = p.scale_to_zero
      values        = p.values
    }
  }

  operators_values = concat(
    [templatefile("${local.values_dir}/armonik-operators.yaml", local.values)],
    var.operators_values,
  )
  armonik_values = concat(
    [
      templatefile("${local.values_dir}/armonik.yaml", local.values),
      yamlencode(local.workers_placement),
      yamlencode(local.promql_partitions),
      yamlencode(local.fast_hpa_partitions),
    ],
    var.armonik_values,
  )
}
