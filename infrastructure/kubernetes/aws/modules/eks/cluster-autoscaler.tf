# A component that automatically adjusts the size of a Kubernetes Cluster so that all pods have a place to run and there are no unneeded nodes
resource "helm_release" "cluster_autoscaler" {
  name       = "armonik"
  chart      = "cluster-autoscaler"
  repository = "https://kubernetes.github.io/autoscaler"

  # Method 1 - Using Autodiscovery
  set {
    name  = "autoDiscovery.clusterName"
    value = var.eks.cluster_name
  }
  set {
    name  = "awsRegion"
    value = var.eks.region
  }
  set {
    name  = "cloudProvider"
    value = "aws"
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

  values = [file("${path.module}/manifests/cluster_autoscaler.yaml")]
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
  name_prefix = "eks-worker-autoscaling-${module.eks.cluster_id}"
  description = "EKS worker node autoscaling policy for cluster ${module.eks.cluster_id}"
  policy      = data.aws_iam_policy_document.worker_autoscaling_document.json
}

resource "aws_iam_role_policy_attachment" "workers_autoscaling_attach" {
  policy_arn = aws_iam_policy.worker_autoscaling_policy.arn
  role       = module.eks.worker_iam_role_name
}

