from typing import Optional

from msgspec import Struct, json


class VpcConfig(Struct):
    name: str
    cidr: str = "10.0.0.0/16"


class Config(Struct):
    region: str
    account: str
    user_role: str
    stack_name: str
    ecr_images: list[str]
    vpc: Optional[VpcConfig] = None


def get_config(path: str) -> Config:
    with open(path, "rb") as f:
        return json.decode(f.read(), type=Config)
