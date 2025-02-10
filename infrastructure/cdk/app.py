#!/usr/bin/env python3
import os

import aws_cdk as cdk

from armonik_cdk.armonik_cdk_stack import ArmonikCdkStack, ArmoniKECRStack, ArmoniKAutoScaler
from armonik_cdk.config import get_config

config_path = os.path.join(os.path.dirname(__file__), "config.json")

config = get_config(config_path)

app = cdk.App()
ArmoniKECRStack(
    app,
    config.stack_name + "-ecr",
    config,
    env=cdk.Environment(account=config.account, region=config.region),
)
eks_stack = ArmonikCdkStack(
    app,
    config.stack_name,
    config,
    env=cdk.Environment(account=config.account, region=config.region),
)
ArmoniKAutoScaler(
    app,
    config.stack_name + "-autoscaler",
    config,
    env=cdk.Environment(account=config.account, region=config.region),
    cluster=eks_stack.cluster,
    extra_ng=eks_stack.extra_ng
)

app.synth()
