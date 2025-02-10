from aws_cdk import Stack
from constructs import Construct

from aws_cdk import aws_eks as eks
from armonik_cdk.config import Config
from armonik_cdk.ecr import gen_ecr
from armonik_cdk.eks import get_eks, gen_autoscaler


class ArmonikCdkStack(Stack):
    def __init__(
        self, scope: Construct, construct_id: str, config: Config, **kwargs
    ) -> None:
        super().__init__(scope, construct_id, **kwargs)
        self.cluster, self.extra_ng = get_eks(self, config)


class ArmoniKECRStack(Stack):
    def __init__(
        self, scope: Construct, construct_id: str, config: Config, **kwargs
    ) -> None:
        super().__init__(scope, construct_id, **kwargs)
        gen_ecr(self, config, config.ecr_images)

class ArmoniKAutoScaler(Stack):
    def __init__(
        self, scope: Construct, construct_id: str, config: Config, cluster: eks.Cluster, extra_ng: eks.Nodegroup, **kwargs
    ) -> None:
        super().__init__(scope, construct_id, **kwargs)
        gen_autoscaler(self, config, cluster, extra_ng)
