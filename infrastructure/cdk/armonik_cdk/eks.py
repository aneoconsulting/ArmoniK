from aws_cdk import Stack
from aws_cdk.aws_eks import Cluster, KubernetesVersion
import aws_cdk.aws_eks as eks

from armonik_cdk.config import Config
from aws_cdk.aws_iam import ArnPrincipal
import aws_cdk.aws_ec2 as ec2


def get_eks(stack: Stack, config: Config) -> Cluster:
    cluster = Cluster(
        stack,
        "eks-armonik-cf",
        default_capacity=5,
        version=KubernetesVersion.V1_29,
        bootstrap_cluster_creator_admin_permissions=True,
        default_capacity_instance=ec2.InstanceType.of(
            ec2.InstanceClass.C5, ec2.InstanceSize.LARGE
        ),
        authentication_mode=eks.AuthenticationMode.API_AND_CONFIG_MAP,
    )
    cluster.add_nodegroup_capacity(
        "custom-node-group",
        instance_types=[ec2.InstanceType("c5.large")],
        max_size=100,
        min_size=0,
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
    return cluster
