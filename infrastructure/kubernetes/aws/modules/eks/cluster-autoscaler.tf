/*locals {
  cluster_autoscaler_placement_config = <<EOF
extraArgs:
  logtostderr: true
  stderrthreshold: info
  v: 4
  aws-use-static-instance-list: ${var.cluster_autoscaler_resources.use_static_instance_list}

resources:
  limits:
    cpu: ${var.cluster_autoscaler_resources.limits.cpu}
    memory: ${var.cluster_autoscaler_resources.limits.memory}
  requests:
    cpu: ${var.cluster_autoscaler_resources.requests.cpu}
    memory: ${var.cluster_autoscaler_resources.requests.memory}

nodeSelector:
  grid/type: "Operator"

tolerations:
  - key: "grid/type"
    operator: "Equal"
    value: "Operator"
    effect: "NoSchedule"
EOF
}

resource "local_file" "cluster_autoscaler_placement_config_file" {
  content  = local.cluster_autoscaler_placement_config
  filename = "./generated/eks/cluster_autoscaler_placement_config.yaml"
}

resource "helm_release" "cluster_autoscaler" {
  name       = "cluster-autoscaler"
  chart      = "cluster-autoscaler"
  namespace  = "kube-system"
  repository = "https://kubernetes.github.io/autoscaler"

  set {
    name  = "autoDiscovery.clusterName"
    value = var.eks.cluster_name
  }
  set {
    name  = "awsRegion"
    value = var.eks.region
  }

  values = [yamlencode(local.cluster_autoscaler_placement_config)]
}*/

