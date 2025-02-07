from aws_cdk import Stack
from constructs import Construct

from armonik_cdk.config import Config
from armonik_cdk.ecr import gen_ecr
from armonik_cdk.eks import get_eks


class ArmonikCdkStack(Stack):
    def __init__(
        self, scope: Construct, construct_id: str, config: Config, **kwargs
    ) -> None:
        super().__init__(scope, construct_id, **kwargs)
        get_eks(self, config)


class ArmoniKECRStack(Stack):
    def __init__(
        self, scope: Construct, construct_id: str, config: Config, **kwargs
    ) -> None:
        super().__init__(scope, construct_id, **kwargs)
        gen_ecr(self, config, config.ecr_images)
