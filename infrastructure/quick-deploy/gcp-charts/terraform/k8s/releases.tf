# Helm releases, in dependency order. The values files of ../../values are templates: ${VARIABLE} comes from
# local.values below, and a literal ${ must be written $${.
# Never wait_for_jobs: the ArmoniK init Jobs delete themselves one second after they end.

locals {
  values_dir       = "${path.module}/../../values"
  chart_repository = "oci://registry-1.docker.io/dockerhubaneo"

  values = {
    PROJECT               = local.gcp.project
    OPERATORS_NS          = local.gcp.namespaces.operators
    SA_CONTROL_PLANE      = local.gcp.service_accounts.control_plane
    SA_COMPUTE_PLANE      = local.gcp.service_accounts.compute_plane
    WORKERS_KEY           = local.gcp.workers.key
    WORKERS_VALUE         = local.gcp.workers.value
    BUCKET                = local.gcp.bucket
    PUBSUB_PREFIX         = local.gcp.pubsub_prefix
    INGRESS_SOURCE_RANGES = join(",", var.ingress_allowed_cidrs)
    CORE_VERSION          = var.versions.core
    GUI_VERSION           = var.versions.gui
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

# External Secrets, KEDA, cert-manager, CloudNativePG and kube-prometheus-stack. Their CRDs must exist before
# the armonik release renders its custom resources.
resource "helm_release" "armonik_operators" {
  name             = "armonik-operators"
  namespace        = local.gcp.namespaces.operators
  create_namespace = true
  repository       = local.chart_repository
  chart            = "armonik-operators"
  version          = var.versions.armonik
  values           = [templatefile("${local.values_dir}/armonik-operators.yaml", local.values)]
  wait             = true
  # Many images on the first install
  timeout = 900
}

resource "helm_release" "armonik" {
  name       = "armonik"
  namespace  = kubernetes_namespace_v1.armonik.metadata[0].name
  repository = local.chart_repository
  chart      = "armonik"
  version    = var.versions.armonik
  values = [
    templatefile("${local.values_dir}/armonik.yaml", local.values),
    yamlencode(local.partitions_values),
  ]
  wait          = true
  wait_for_jobs = false
  # PostgreSQL first, then the init Jobs, then the control and compute planes
  timeout = 1200

  depends_on = [helm_release.armonik_operators, kubernetes_secret_v1.grafana_admin]
}
