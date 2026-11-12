# Helm releases, in dependency order. The values files of values/ are templates: ${VARIABLE} comes from
# local.values below, and a literal ${ must be written $${.
# Never wait_for_jobs: the ArmoniK init Jobs delete themselves one second after they end.

locals {
  chart_repository = "oci://registry-1.docker.io/dockerhubaneo"

  values = {
    PROJECT          = var.project
    OPERATORS_NS     = local.namespaces.operators
    SA_CONTROL_PLANE = local.service_accounts.control_plane
    SA_COMPUTE_PLANE = local.service_accounts.compute_plane
    BUCKET           = module.object_storage.name
    PG_HOST          = module.database.host
    # The poolers when enabled, the replication connection of Core included (same host and port as its pool)
    PG_PORT               = coalesce(module.database.pooler_port, module.database.port)
    PG_DATABASE           = module.database.database
    PG_SECRET             = kubernetes_secret_v1.postgresql.metadata[0].name
    PG_CA_SECRET          = kubernetes_secret_v1.postgresql_ca.metadata[0].name
    PUBSUB_PREFIX         = var.prefix
    INGRESS_SOURCE_RANGES = join(",", var.ingress_allowed_cidrs)
    CORE_VERSION          = var.versions.core
    GUI_VERSION           = var.versions.gui
    # Image prefixes of the pull-through caches (registry.tf)
    REG_DOCKERHUB = module.registry.urls.dockerhub
    REG_GHCR      = module.registry.urls.ghcr
    REG_QUAY      = module.registry.urls.quay
    REG_K8S       = module.registry.urls.k8s
  }

  # var.partitions as compute-plane values, over the partitionCommon of values/armonik.yaml
  partitions_values = {
    compute-plane = {
      partitions = {
        for name, p in var.partitions : name => {
          hpa = { maxReplicaCount = p.max_replicas }
          worker = {
            image = {
              registry   = split("/", p.image)[0]
              repository = join("/", slice(split("/", p.image), 1, length(split("/", p.image))))
              tag        = p.tag
            }
            resources = {
              requests = { cpu = p.cpu, memory = p.memory }
              limits   = { cpu = p.cpu, memory = p.memory }
            }
          }
        }
      }
    }
  }
}

# External Secrets, KEDA, cert-manager and kube-prometheus-stack. Their CRDs must exist before the
# armonik release renders its custom resources. Its pods go to the default ComputeClass, which must exist first.
resource "helm_release" "armonik_operators" {
  name             = "armonik-operators"
  namespace        = local.namespaces.operators
  create_namespace = true
  repository       = local.chart_repository
  chart            = "armonik-operators"
  version          = var.versions.armonik
  values           = [templatefile("${path.module}/values/armonik-operators.yaml", local.values)]
  wait             = true
  # First nodes created by the ComputeClasses, and many images pulled into the caches
  timeout = 1200

  depends_on = [kubectl_manifest.compute_class]
}

resource "helm_release" "armonik" {
  name       = "armonik"
  namespace  = kubernetes_namespace_v1.armonik.metadata[0].name
  repository = local.chart_repository
  chart      = "armonik"
  version    = var.versions.armonik
  values = [
    templatefile("${path.module}/values/armonik.yaml", local.values),
    yamlencode(local.partitions_values),
    # The law and the HPA of each partition (autoscaling.tf)
    yamlencode(local.autoscaling_law_values),
    yamlencode(local.autoscaling_hpa_values),
    # A values document of its own, so that Helm merges it deeply rather than replacing whole maps
    yamlencode({ compute-plane = { partitions = { for name, p in var.partitions : name => yamldecode(p.values) } } }),
  ]
  wait          = true
  wait_for_jobs = false
  # The init Jobs, then the control and compute planes
  timeout = 1200

  depends_on = [
    helm_release.armonik_operators,
    kubernetes_secret_v1.grafana_admin,
    kubernetes_secret_v1.postgresql,
    kubernetes_secret_v1.postgresql_ca,
    module.service_accounts,
    module.object_storage,
    # The partitions on a PromQL law read these rules
    kubectl_manifest.autoscaling_rules,
  ]
}
