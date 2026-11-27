locals {
  # The system node group: the components that must not run on the nodes Karpenter manages, and those of kube-system
  system_selector = { (local.pool_label) = "system" }
  system_tolerations = [{
    key      = local.pool_label
    operator = "Equal"
    value    = "system"
    effect   = "NoSchedule"
  }]

  # Set on every node at its creation, removed by the Cilium agent once the pod network of the node is ready: the
  # agent_not_ready_taint output of the cilium module, written out here since the eks module, which the cilium module
  # reads, takes it as an input
  cilium_taint = { key = "node.cilium.io/agent-not-ready", value = "true", effect = "NoExecute" }
}

module "eks" {
  source = "git::https://github.com/aneoconsulting/ArmoniK.Infra.git//kubernetes/aws/eks?ref=dw/aws-charts-modules"

  name            = local.name
  region          = var.region
  profile         = var.profile
  kubeconfig_file = "${path.root}/generated/kubeconfig"
  cluster_version = var.eks.kubernetes_version

  vpc_id                 = module.vpc.id
  vpc_private_subnet_ids = module.vpc.private_subnets
  vpc_pods_subnet_ids    = []

  cluster_endpoint_private_access      = true
  cluster_endpoint_public_access       = true
  cluster_endpoint_public_access_cidrs = var.eks.endpoint_public_access_cidrs

  cluster_create_kms_key        = false
  cluster_encryption_config     = module.kms.key_arn
  cluster_log_kms_key_id        = module.kms.key_arn
  cluster_log_retention_in_days = 7
  ebs_kms_key_id                = ""

  # Karpenter, the EBS CSI driver and the ArmoniK planes get their AWS credentials from EKS Pod Identity
  pod_identity = true

  # Karpenter scales the nodes and drains them on spot interruptions
  cluster_autoscaler_enabled = false
  instance_refresh_enabled   = false

  # Cilium (below) gives the pods their network and implements the Services
  vpc_cni_enabled    = false
  kube_proxy_enabled = false

  # CoreDNS and the CSI controllers, on the system node group
  node_selector = local.system_selector

  eks_managed_node_groups = {
    system = {
      ami_type       = "AL2023_x86_64_STANDARD"
      instance_types = var.eks.system_instance_types
      min_size       = var.eks.system_node_group_size
      max_size       = var.eks.system_node_group_size
      desired_size   = var.eks.system_node_group_size
      labels         = local.system_selector
      taints = {
        system = {
          key    = local.pool_label
          value  = "system"
          effect = "NO_SCHEDULE"
        }
        cilium = {
          key    = local.cilium_taint.key
          value  = local.cilium_taint.value
          effect = "NO_EXECUTE"
        }
      }
      iam_role_additional_policies = local.node_iam_policies
    }
  }

  tags = local.tags
}

# CNI in ENI mode, kube-proxy replaced. Reads only the cluster, not the node groups: the nodes stay NotReady until its
# agent runs on them, and the coredns add-on of the eks module waits for Ready nodes, so the release installs while
# the node groups are created.
module "cilium" {
  source = "git::https://github.com/aneoconsulting/ArmoniK.Infra.git//kubernetes/aws/cilium?ref=dw/aws-charts-modules"

  cluster_name           = module.eks.cluster_name
  cluster_endpoint       = module.eks.cluster_endpoint
  native_routing_cidr    = var.vpc.cidr
  chart_version          = var.versions.cilium
  image_registry         = local.registries.quay
  operator_node_selector = local.system_selector

  tags = local.tags
}

# cilium-health probes every node with ICMP echo (and TCP 4240, inside the node-to-node ephemeral range the eks module
# opens): without it, cilium status reports the other nodes unreachable
resource "aws_vpc_security_group_ingress_rule" "nodes_icmp" {
  security_group_id            = module.eks.node_security_group_id
  description                  = "cilium-health ICMP echo between nodes"
  ip_protocol                  = "icmp"
  from_port                    = 8
  to_port                      = 0
  referenced_security_group_id = module.eks.node_security_group_id
  tags                         = local.tags
}

# The system nodes running: what schedules pods on them waits for this, rather than for the whole eks module
resource "terraform_data" "system_nodes" {
  input = {
    cluster_name = module.eks.cluster_name
    node_group   = module.eks.eks_managed_node_groups["system"].node_group_id
  }
}

# Default storage class (Seq, Prometheus), through the EBS CSI add-on of the eks module
resource "kubernetes_storage_class_v1" "gp3" {
  metadata {
    name = "gp3"
    annotations = {
      "storageclass.kubernetes.io/is-default-class" = "true"
    }
  }
  storage_provisioner    = "ebs.csi.aws.com"
  volume_binding_mode    = "WaitForFirstConsumer"
  allow_volume_expansion = true
  reclaim_policy         = "Delete"
  parameters = {
    type      = "gp3"
    encrypted = "true"
  }
}

module "karpenter" {
  source = "git::https://github.com/aneoconsulting/ArmoniK.Infra.git//kubernetes/aws/karpenter?ref=dw/aws-charts-modules"

  cluster_name       = terraform_data.system_nodes.output.cluster_name
  security_group_ids = [module.eks.node_security_group_id]
  chart_version      = var.versions.karpenter
  image_registry     = local.registries.ecrPublic

  controller_node_selector = local.system_selector
  controller_values = [yamlencode({
    tolerations = concat(local.system_tolerations, [{ key = "CriticalAddonsOnly", operator = "Exists" }])
  })]

  node_iam_role_additional_policies = local.node_iam_policies
  pool_label                        = local.pool_label
  # In the zone of the S3 Express bucket when pinned (object_storage.pin_to_express_zone)
  node_pools     = { for name, pool in var.node_pools : name => merge(pool, { zones = local.node_zones }) }
  startup_taints = [local.cilium_taint]

  tags = local.tags
}

# Turns the ingress Service of type LoadBalancer into an NLB whose targets are the ingress pods (IP mode)
module "aws_load_balancer_controller_identity" {
  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "2.10.0"

  name            = "${local.name}-aws-lb-controller"
  use_name_prefix = false
  # The default AmazonEKS_ name is account wide: two stacks in one account would collide
  policy_name_prefix = "${local.name}-"

  attach_aws_lb_controller_policy = true

  associations = {
    controller = {
      cluster_name    = terraform_data.system_nodes.output.cluster_name
      namespace       = "kube-system"
      service_account = "aws-load-balancer-controller"
    }
  }

  tags = local.tags
}

# HTTP repository only, so the chart is pulled from its upstream (its image through the ECR cache)
resource "helm_release" "aws_load_balancer_controller" {
  name       = "aws-load-balancer-controller"
  namespace  = "kube-system"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  version    = var.versions.lbc
  values = [yamlencode({
    clusterName = module.aws_load_balancer_controller_identity.associations.controller.cluster_name
    # Stated since the IMDS of the nodes is out of the reach of the pods (hop limit 1)
    region = var.region
    vpcId  = module.vpc.id
    # Reuse the webhook TLS secret on upgrade: the chart otherwise generates a new CA on every render, and the armonik
    # release may hit the webhook while the controller still serves the old one
    keepTLSSecret = true
    serviceAccount = {
      create = true
      name   = module.aws_load_balancer_controller_identity.associations.controller.service_account
    }
    image        = { repository = "${local.registries.ecrPublic}/eks/aws-load-balancer-controller" }
    nodeSelector = local.system_selector
    tolerations  = local.system_tolerations
  })]
  wait = true
}

# Resource metrics API: the KEDA cpu triggers of the control plane Deployments (values/armonik.yaml) read the pods' CPU
# from it. EKS does not install it.
resource "helm_release" "metrics_server" {
  name       = "metrics-server"
  namespace  = "kube-system"
  repository = "https://kubernetes-sigs.github.io/metrics-server/"
  chart      = "metrics-server"
  version    = var.versions.metrics_server
  values = [yamlencode({
    image        = { repository = "${local.registries.k8s}/metrics-server/metrics-server" }
    nodeSelector = local.system_selector
    tolerations  = local.system_tolerations
  })]
  wait = true
}
