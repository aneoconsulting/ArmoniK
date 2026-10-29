# Helm releases, in dependency order. The values files of ../values are templates: ${VARIABLE} comes from
# local.values below, and a literal ${ must be written $${.
# Never wait_for_jobs: the ArmoniK init Jobs delete themselves one second after they end.

locals {
  values_dir = "${path.module}/../../values"
  charts_dir = "${path.module}/../../charts"

  values = {
    CLUSTER_NAME            = local.aws.cluster_name
    AWS_REGION              = local.aws.region
    VPC_ID                  = local.aws.vpc_id
    ARMONIK_NS              = local.aws.namespaces.armonik
    OPERATORS_NS            = local.aws.namespaces.operators
    SA_CONTROL_PLANE        = local.aws.service_accounts.control_plane
    SA_COMPUTE_PLANE        = local.aws.service_accounts.compute_plane
    KARPENTER_NODE_ROLE     = local.aws.karpenter.node_role
    KARPENTER_QUEUE         = local.aws.karpenter.queue_name
    KARPENTER_DISCOVERY_TAG = local.aws.karpenter.discovery_tag
    PG_HOST                 = local.aws.postgresql.host
    PG_PORT                 = local.aws.postgresql.port
    PG_DATABASE             = local.aws.postgresql.database
    PG_SECRET_ARN           = local.aws.postgresql.secret_arn
    PG_CA_SECRET_ARN        = local.aws.postgresql.ca_secret_arn
    SQS_PREFIX              = local.aws.sqs_prefix
    S3_BUCKET               = local.aws.s3_bucket
    REG_DOCKERHUB           = local.aws.registries.dockerHub
    REG_GHCR                = local.aws.registries.ghcr
    REG_QUAY                = local.aws.registries.quay
    REG_K8S                 = local.aws.registries.k8s
    REG_ECR_PUBLIC          = local.aws.registries.ecrPublic
    INGRESS_SOURCE_RANGES   = join(",", var.ingress_allowed_cidrs)
    CORE_VERSION            = var.versions.core
    GUI_VERSION             = var.versions.gui
  }

  # Core reads its PostgreSQL connection string from the Secret of the postgresql-connection release
  # when var.postgresql_connection_options is set: it then ignores Host, User and Password
  postgresql_connection = var.postgresql_connection_options == "" ? {} : {
    conf = {
      core = {
        envFromSecret = {
          PostgreSQL__ConnectionString = {
            secret = "armonik-postgresql-connection"
            field  = "connectionString"
          }
        }
      }
    }
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

resource "helm_release" "karpenter" {
  name       = "karpenter"
  namespace  = "kube-system"
  repository = "oci://${local.aws.registries.ecrPublic}/karpenter"
  chart      = "karpenter"
  version    = var.versions.karpenter
  values     = [templatefile("${local.values_dir}/karpenter.yaml", local.values)]
  wait       = true
}

resource "helm_release" "karpenter_nodes" {
  name      = "karpenter-nodes"
  namespace = "kube-system"
  chart     = "${local.charts_dir}/karpenter-nodes"
  values    = [templatefile("${local.values_dir}/karpenter-nodes.yaml", local.values)]
  wait      = true

  depends_on = [helm_release.karpenter]
}

# HTTP repository only, so the chart is not pulled through the ECR cache (its image is)
resource "helm_release" "aws_load_balancer_controller" {
  name       = "aws-load-balancer-controller"
  namespace  = "kube-system"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  version    = var.versions.lbc
  values     = [templatefile("${local.values_dir}/aws-load-balancer-controller.yaml", local.values)]
  wait       = true

  depends_on = [helm_release.karpenter_nodes]
}

resource "helm_release" "armonik_operators" {
  name             = "armonik-operators"
  namespace        = local.aws.namespaces.operators
  create_namespace = true
  repository       = "oci://${local.aws.registries.dockerHub}/dockerhubaneo"
  chart            = "armonik-operators"
  version          = var.versions.armonik
  values           = [templatefile("${local.values_dir}/armonik-operators.yaml", local.values)]
  wait             = true
  timeout          = 600

  # The LBC webhook mutates every Service: until its pods run, it rejects the operators' Services
  depends_on = [helm_release.aws_load_balancer_controller]
}

resource "helm_release" "aws_secret_store" {
  name      = "aws-secret-store"
  namespace = local.aws.namespaces.operators
  chart     = "${local.charts_dir}/aws-secret-store"
  values    = [templatefile("${local.values_dir}/aws-secret-store.yaml", local.values)]
  wait      = true

  depends_on = [helm_release.armonik_operators]
}

# Npgsql options Core does not expose (auto-prepare, no reset on close), in a full connection string that ESO
# builds from the RDS master user secret. Only with var.postgresql_connection_options.
resource "helm_release" "postgresql_connection" {
  count = var.postgresql_connection_options == "" ? 0 : 1

  name             = "postgresql-connection"
  namespace        = local.aws.namespaces.armonik
  create_namespace = true
  chart            = "${local.charts_dir}/postgresql-connection"
  values = [yamlencode({
    credentialsSecret = local.aws.postgresql.secret_arn
    host              = local.aws.postgresql.host
    port              = local.aws.postgresql.port
    database          = local.aws.postgresql.database
    options           = var.postgresql_connection_options
  })]
  wait = true

  depends_on = [helm_release.aws_secret_store]
}

resource "helm_release" "armonik" {
  name             = "armonik"
  namespace        = local.aws.namespaces.armonik
  create_namespace = true
  repository       = "oci://${local.aws.registries.dockerHub}/dockerhubaneo"
  chart            = "armonik"
  version          = var.versions.armonik
  values = [
    templatefile("${local.values_dir}/armonik.yaml", local.values),
    yamlencode(local.partitions_values),
    yamlencode(local.postgresql_connection),
  ]
  wait    = true
  timeout = 900

  depends_on = [
    helm_release.aws_secret_store,
    helm_release.aws_load_balancer_controller,
    helm_release.postgresql_connection,
  ]
}
