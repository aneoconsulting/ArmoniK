# ECR pull-through cache: every image and chart is pulled through <registry>/<prefix>/<upstream>/...,
# the repository being created on the first pull. cr.fluentbit.io is not a supported upstream: the
# charts are pointed at the same fluent-bit image on Docker Hub instead.
locals {
  registry = "${local.account_id}.dkr.ecr.${var.region}.amazonaws.com"

  pull_through_cache = {
    docker-hub = { key = "dockerHub", upstream = "registry-1.docker.io", credentials = "docker_hub" }
    ghcr       = { key = "ghcr", upstream = "ghcr.io", credentials = "github" }
    quay       = { key = "quay", upstream = "quay.io", credentials = null }
    k8s        = { key = "k8s", upstream = "registry.k8s.io", credentials = null }
    ecr-public = { key = "ecrPublic", upstream = "public.ecr.aws", credentials = null }
  }

  # Where each upstream is reachable from the cluster, consumed by the helmfile
  registries = {
    for name, cache in local.pull_through_cache : cache.key => "${local.registry}/${local.name}/${name}"
  }
}

# The secret name must start with ecr-pullthroughcache/
resource "aws_secretsmanager_secret" "pull_through_cache" {
  for_each = toset(["docker_hub", "github"])

  name                    = "ecr-pullthroughcache/${local.name}-${replace(each.key, "_", "-")}"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "pull_through_cache" {
  for_each = aws_secretsmanager_secret.pull_through_cache

  secret_id = each.value.id
  secret_string_wo = jsonencode({
    username    = var.registry_credentials[each.key].username
    accessToken = var.registry_credentials[each.key].access_token
  })
  secret_string_wo_version = var.registry_credentials_version
}

resource "aws_ecr_pull_through_cache_rule" "this" {
  for_each = local.pull_through_cache

  ecr_repository_prefix = "${local.name}/${each.key}"
  upstream_registry_url = each.value.upstream
  credential_arn        = each.value.credentials == null ? null : aws_secretsmanager_secret.pull_through_cache[each.value.credentials].arn

  depends_on = [aws_secretsmanager_secret_version.pull_through_cache]
}

# Settings of the repositories the cache creates. They are not in the state: make delete removes them.
# No resource_tags: tagging needs a custom_role_arn, the ECR service-linked role lacking ecr:TagResource,
# and without it every repository creation fails, so every pull returns "not found".
resource "aws_ecr_repository_creation_template" "pull_through_cache" {
  prefix      = local.name
  description = "ArmoniK ${local.name} pull-through cache"
  applied_for = ["PULL_THROUGH_CACHE"]

  image_tag_mutability = "MUTABLE"

  encryption_configuration {
    encryption_type = "AES256"
  }

  lifecycle_policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep the 10 most recent images"
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = 10
      }
      action = { type = "expire" }
    }]
  })
}

# A pull through the cache creates the repository and imports the image on behalf of the caller
data "aws_iam_policy_document" "ecr_pull_through_cache" {
  statement {
    sid = "PullThroughCache"
    actions = [
      "ecr:BatchImportUpstreamImage",
      "ecr:CreateRepository",
      "ecr:BatchGetImage",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchCheckLayerAvailability",
    ]
    resources = ["arn:${local.partition}:ecr:${var.region}:${local.account_id}:repository/${local.name}/*"]
  }

  statement {
    sid       = "Authorization"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "ecr_pull_through_cache" {
  name_prefix = "${local.name}-ecr-pull-through-"
  description = "Pull images through the ${local.name} ECR pull-through cache"
  policy      = data.aws_iam_policy_document.ecr_pull_through_cache.json
}
