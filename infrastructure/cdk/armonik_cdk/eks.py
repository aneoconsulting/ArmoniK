from aws_cdk import Stack
from aws_cdk.aws_eks import Cluster, KubernetesVersion
import aws_cdk.aws_eks as eks
from aws_cdk.lambda_layer_kubectl_v29 import KubectlV29Layer
from aws_cdk import aws_iam as iam

from armonik_cdk.config import Config
from aws_cdk.aws_iam import ArnPrincipal
import aws_cdk.aws_ec2 as ec2


def get_eks(stack: Stack, config: Config) -> tuple[Cluster, eks.Nodegroup]:
    cluster = Cluster(
        stack,
        "eks-armonik-cf",
        default_capacity=1,
        version=KubernetesVersion.of("1.29"),
        bootstrap_cluster_creator_admin_permissions=True,
        default_capacity_instance=ec2.InstanceType.of(
            ec2.InstanceClass.C5, ec2.InstanceSize.LARGE
        ),
        authentication_mode=eks.AuthenticationMode.API_AND_CONFIG_MAP,
        kubectl_layer=KubectlV29Layer(stack, "kubectl-layer"),
    )

    extra_node_group = cluster.add_nodegroup_capacity(
        "custom-node-group",
        instance_types=[ec2.InstanceType("c5d.large")],
        max_size=100,
        min_size=1,
    )
    cluster.grant_access(
        id="eks_access_grant",
        principal=ArnPrincipal(arn=config.user_role).arn,
        access_policies=[
            eks.AccessPolicy.from_access_policy_name(
                "AmazonEKSClusterAdminPolicy",
                access_scope_type=eks.AccessScopeType.CLUSTER,
            )
        ],
    )
    return cluster, extra_node_group

def gen_autoscaler(stack, config, cluster: eks.Cluster, extra_node_group:eks.Nodegroup):
    capacity_statement = iam.PolicyStatement(
        actions=[
            "autoscaling:SetDesiredCapacity",
            "autoscaling:TerminateInstanceInAutoScalingGroup",
        ],
        resources=["*"]
    )
    # cluster_name = CfnParameter(stack, "cluster-name", default=cluster_name)
    # resource_condition = CfnJson(stack, 'resource-condition', value={
    #     f"aws:ResourceTag/k8s.io/cluster-autoscaler/{cluster_name.value_as_string}": "owned",
    # })
    # capacity_statement.add_condition("StringEquals", resource_condition)
    capacity_statement.add_condition("StringEquals", {"aws:ResourceTag/k8s.io/cluster-autoscaler/enabled": "true"})
    autoscaler_policy = iam.Policy(
        stack,
        "autoscaler-policy",
        statements=[
            iam.PolicyStatement(
                actions=[
                    "autoscaling:DescribeAutoScalingGroups",
                    "autoscaling:DescribeAutoScalingInstances",
                    "autoscaling:DescribeLaunchConfigurations",
                    "autoscaling:DescribeScalingActivities",
                    "autoscaling:DescribeTags",
                    "ec2:DescribeImages",
                    "ec2:DescribeInstanceTypes",
                    "ec2:DescribeLaunchTemplateVersions",
                    "ec2:GetInstanceTypesFromInstanceRequirements",
                    "eks:DescribeNodegroup",
                ],
                resources=["*"],
            )
        ],
    )
    autoscaler_policy.add_statements(capacity_statement)
    cluster.default_nodegroup.role.attach_inline_policy(autoscaler_policy)
    extra_node_group.role.attach_inline_policy(autoscaler_policy)
    cluster.add_manifest(
        "cluster-autoscaler",
        *(
            {
                "apiVersion": "v1",
                "kind": "ServiceAccount",
                "metadata": {
                    "labels": {
                        "k8s-addon": "cluster-autoscaler.addons.k8s.io",
                        "k8s-app": "cluster-autoscaler",
                    },
                    "name": "cluster-autoscaler",
                    "namespace": "kube-system",
                },
            },
            {
                "apiVersion": "rbac.authorization.k8s.io/v1",
                "kind": "ClusterRole",
                "metadata": {
                    "name": "cluster-autoscaler",
                    "labels": {
                        "k8s-addon": "cluster-autoscaler.addons.k8s.io",
                        "k8s-app": "cluster-autoscaler",
                    },
                },
                "rules": [
                    {
                        "apiGroups": [""],
                        "resources": ["events", "endpoints"],
                        "verbs": ["create", "patch"],
                    },
                    {
                        "apiGroups": [""],
                        "resources": ["pods/eviction"],
                        "verbs": ["create"],
                    },
                    {
                        "apiGroups": [""],
                        "resources": ["pods/status"],
                        "verbs": ["update"],
                    },
                    {
                        "apiGroups": [""],
                        "resources": ["endpoints"],
                        "resourceNames": ["cluster-autoscaler"],
                        "verbs": ["get", "update"],
                    },
                    {
                        "apiGroups": [""],
                        "resources": ["nodes"],
                        "verbs": ["watch", "list", "get", "update"],
                    },
                    {
                        "apiGroups": [""],
                        "resources": [
                            "namespaces",
                            "pods",
                            "services",
                            "replicationcontrollers",
                            "persistentvolumeclaims",
                            "persistentvolumes",
                        ],
                        "verbs": ["watch", "list", "get"],
                    },
                    {
                        "apiGroups": ["extensions"],
                        "resources": ["replicasets", "daemonsets"],
                        "verbs": ["watch", "list", "get"],
                    },
                    {
                        "apiGroups": ["policy"],
                        "resources": ["poddisruptionbudgets"],
                        "verbs": ["watch", "list"],
                    },
                    {
                        "apiGroups": ["apps"],
                        "resources": ["statefulsets", "replicasets", "daemonsets"],
                        "verbs": ["watch", "list", "get"],
                    },
                    {
                        "apiGroups": ["storage.k8s.io"],
                        "resources": [
                            "storageclasses",
                            "csinodes",
                            "csidrivers",
                            "csistoragecapacities",
                        ],
                        "verbs": ["watch", "list", "get"],
                    },
                    {
                        "apiGroups": ["batch", "extensions"],
                        "resources": ["jobs"],
                        "verbs": ["get", "list", "watch", "patch"],
                    },
                    {
                        "apiGroups": ["coordination.k8s.io"],
                        "resources": ["leases"],
                        "verbs": ["create"],
                    },
                    {
                        "apiGroups": ["coordination.k8s.io"],
                        "resourceNames": ["cluster-autoscaler"],
                        "resources": ["leases"],
                        "verbs": ["get", "update"],
                    },
                ],
            },
            {
                "apiVersion": "rbac.authorization.k8s.io/v1",
                "kind": "Role",
                "metadata": {
                    "name": "cluster-autoscaler",
                    "namespace": "kube-system",
                    "labels": {
                        "k8s-addon": "cluster-autoscaler.addons.k8s.io",
                        "k8s-app": "cluster-autoscaler",
                    },
                },
                "rules": [
                    {
                        "apiGroups": [""],
                        "resources": ["configmaps"],
                        "verbs": ["create", "list", "watch"],
                    },
                    {
                        "apiGroups": [""],
                        "resources": ["configmaps"],
                        "resourceNames": [
                            "cluster-autoscaler-status",
                            "cluster-autoscaler-priority-expander",
                        ],
                        "verbs": ["delete", "get", "update", "watch"],
                    },
                ],
            },
            {
                "apiVersion": "rbac.authorization.k8s.io/v1",
                "kind": "ClusterRoleBinding",
                "metadata": {
                    "name": "cluster-autoscaler",
                    "labels": {
                        "k8s-addon": "cluster-autoscaler.addons.k8s.io",
                        "k8s-app": "cluster-autoscaler",
                    },
                },
                "roleRef": {
                    "apiGroup": "rbac.authorization.k8s.io",
                    "kind": "ClusterRole",
                    "name": "cluster-autoscaler",
                },
                "subjects": [
                    {
                        "kind": "ServiceAccount",
                        "name": "cluster-autoscaler",
                        "namespace": "kube-system",
                    }
                ],
            },
            {
                "apiVersion": "rbac.authorization.k8s.io/v1",
                "kind": "RoleBinding",
                "metadata": {
                    "name": "cluster-autoscaler",
                    "namespace": "kube-system",
                    "labels": {
                        "k8s-addon": "cluster-autoscaler.addons.k8s.io",
                        "k8s-app": "cluster-autoscaler",
                    },
                },
                "roleRef": {
                    "apiGroup": "rbac.authorization.k8s.io",
                    "kind": "Role",
                    "name": "cluster-autoscaler",
                },
                "subjects": [
                    {
                        "kind": "ServiceAccount",
                        "name": "cluster-autoscaler",
                        "namespace": "kube-system",
                    }
                ],
            },
            {
                "apiVersion": "apps/v1",
                "kind": "Deployment",
                "metadata": {
                    "name": "cluster-autoscaler",
                    "namespace": "kube-system",
                    "labels": {"app": "cluster-autoscaler"},
                },
                "spec": {
                    "replicas": 1,
                    "selector": {"matchLabels": {"app": "cluster-autoscaler"}},
                    "template": {
                        "metadata": {
                            "labels": {"app": "cluster-autoscaler"},
                            "annotations": {
                                "prometheus.io/scrape": "true",
                                "prometheus.io/port": "8085",
                            },
                        },
                        "spec": {
                            "priorityClassName": "system-cluster-critical",
                            "securityContext": {
                                "runAsNonRoot": True,
                                "runAsUser": 65534,
                                "fsGroup": 65534,
                                "seccompProfile": {"type": "RuntimeDefault"},
                            },
                            "serviceAccountName": "cluster-autoscaler",
                            "containers": [
                                {
                                    "image": f"{config.account}.dkr.ecr.{config.region}.amazonaws.com/aneo/autoscaling/cluster-autoscaler:v1.26.2",
                                    "name": "cluster-autoscaler",
                                    "resources": {
                                        "limits": {"cpu": "100m", "memory": "600Mi"},
                                        "requests": {"cpu": "100m", "memory": "600Mi"},
                                    },
                                    "command": [
                                        "./cluster-autoscaler",
                                        "--v=4",
                                        "--stderrthreshold=info",
                                        "--cloud-provider=aws",
                                        "--skip-nodes-with-local-storage=false",
                                        "--expander=least-waste",
                                        f"--node-group-auto-discovery=asg:tag=k8s.io/cluster-autoscaler/enabled,k8s.io/cluster-autoscaler/{cluster.cluster_name}",
                                    ],
                                    "volumeMounts": [
                                        {
                                            "name": "ssl-certs",
                                            "mountPath": "/etc/ssl/certs/ca-certificates.crt",
                                            "readOnly": True,
                                        }
                                    ],
                                    "imagePullPolicy": "Always",
                                    "securityContext": {
                                        "allowPrivilegeEscalation": False,
                                        "capabilities": {"drop": ["ALL"]},
                                        "readOnlyRootFilesystem": True,
                                    },
                                }
                            ],
                            "volumes": [
                                {
                                    "name": "ssl-certs",
                                    "hostPath": {
                                        "path": "/etc/ssl/certs/ca-bundle.crt"
                                    },
                                }
                            ],
                        },
                    },
                },
            },
        ),
    )

