from aws_cdk import aws_ecr as ecr, Stack

from armonik_cdk.config import Config


def gen_ecr(
    stack: Stack, config: Config, repositories: list[str]
) -> list[ecr.CfnRepository]:
    repos = []
    for tag in repositories:
        repo, image = tag.split("/", maxsplit=1)
        image, tag = image.split(":", maxsplit=1)
        repos.append(
            ecr.CfnRepository(
                stack,
                id=f"armonik-ecr-{image}",
                repository_name=image,
                empty_on_delete=True,
            )
        )
    return repos
