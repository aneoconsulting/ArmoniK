# A component that automatically adjusts the size of a Kubernetes Cluster so that all pods have a place to run and there are no unneeded nodes
resource "helm_release" "cluster_autoscaler" {
  name       = "armonik"
  namespace  = "kube-system"
  chart      = "cluster-autoscaler"
  #repository = "https://kubernetes.github.io/autoscaler"
  repository = "${path.module}/charts"
  version    = "9.14.0"

  # Method 1 - Using Autodiscovery
  set {
    name  = "autoDiscovery.clusterName"
    value = var.name
  }
  set {
    name  = "awsRegion"
    value = local.region
  }
  set {
    name  = "cloudProvider"
    value = "aws"
  }
  set {
    name  = "image.repository"
    value = var.eks.docker_images.cluster_autoscaler.image
  }
  set {
    name  = "image.tag"
    value = var.eks.docker_images.cluster_autoscaler.tag
  }
  set {
    name  = "extraArgs.logtostderr"
    value = true
  }
  set {
    name  = "extraArgs.stderrthreshold"
    value = "Info"
  }
  set {
    name  = "extraArgs.v"
    value = "4"
  }
  set {
    name  = "extraArgs.aws-use-static-instance-list"
    value = true
  }
  set {
    name  = "resources.limits.cpu"
    value = "3000m"
  }
  set {
    name  = "resources.limits.memory"
    value = "3000Mi"
  }
  set {
    name  = "resources.requests.cpu"
    value = "1000m"
  }
  set {
    name  = "resources.requests.memory"
    value = "1000Mi"
  }

  # Method 2 - Specifying groups manually
  # Example for an ASG
  /*set {
    name  = "autoscalingGroups[0].name"
    value = "<your-asg-name>"
  }
  set {
    name  = "autoscalingGroups[0].maxSize"
    value = "10"
  }
  set {
    name  = "autoscalingGroups[0].minSize"
    value = "1"
  }*/

  values     = [
    yamlencode(local.node_selector),
    yamlencode(local.tolerations)
  ]
  depends_on = [
    module.eks,
    null_resource.update_kubeconfig
  ]
}

# Workers Auto Scaling policy
data "aws_iam_policy_document" "worker_autoscaling_document" {
  statement {
    sid       = "eksWorkerAutoscalingAll"
    effect    = "Allow"
    actions   = [
      "autoscaling:DescribeAutoScalingGroups",
      "autoscaling:DescribeAutoScalingInstances",
      "autoscaling:DescribeLaunchConfigurations",
      "autoscaling:DescribeTags",
      "ec2:DescribeLaunchTemplateVersions",
      "ec2:DescribeInstanceTypes",
    ]
    resources = ["*"]
  }
  statement {
    sid       = "eksWorkerAutoscalingOwn"
    effect    = "Allow"
    actions   = [
      "autoscaling:SetDesiredCapacity",
      "autoscaling:TerminateInstanceInAutoScalingGroup",
      "autoscaling:UpdateAutoScalingGroup",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "worker_autoscaling_policy" {
  name_prefix = local.iam_worker_autoscaling_policy_name
  description = "EKS worker node autoscaling policy for cluster ${module.eks.cluster_id}"
  policy      = data.aws_iam_policy_document.worker_autoscaling_document.json
  tags        = local.tags
}

resource "aws_iam_role_policy_attachment" "workers_autoscaling_attach" {
  policy_arn = aws_iam_policy.worker_autoscaling_policy.arn
  role       = module.eks.worker_iam_role_name
}

