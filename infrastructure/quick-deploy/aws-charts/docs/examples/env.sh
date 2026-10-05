# Variables read by docs/examples/values/*.yaml (rendered with envsubst, see docs/helm-cli.md).
#
#   source docs/examples/env.sh
#
# Every value comes from the Terraform outputs of terraform/outputs.tf, or from the infrastructure you
# already have: replace any line below by a literal value and nothing else changes.
#
# Where the outputs are read from, in this order:
#   TF_OUTPUT_JSON  a file holding `terraform output -json`
#   otherwise       `terraform -chdir=$TF_DIR output -json`, which needs `terraform init` to have run
#                   against the same backend. `make init` keeps the Terraform data in generated/, hence
#                   the TF_DATA_DIR default.

# cd output is dropped: some zsh setups print an escape sequence on every cd, which would end up in the path
_qd="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")/../.." >/dev/null && pwd)"
if [ -n "${TF_OUTPUT_JSON:-}" ]; then
  _out="$(cat "$TF_OUTPUT_JSON")"
else
  _out="$(TF_DATA_DIR="${TF_DATA_DIR:-$_qd/generated}" terraform -chdir="${TF_DIR:-$_qd/terraform}" output -json)"
fi
_o() { printf '%s' "$_out" | jq -er "$1"; }

# --- EKS ------------------------------------------------------------------------------------------
export CLUSTER_NAME="$(_o .eks.value.name)"
export AWS_REGION="$(_o .eks.value.region)"
export VPC_ID="$(_o .eks.value.vpc_id)"

# --- Namespaces and service accounts ----------------------------------------------------------------
# The service accounts are bound to IAM roles (EKS Pod Identity) by Terraform, by namespace and name:
# the charts must be told to use exactly these.
export ARMONIK_NS="$(_o .namespaces.value.armonik)"
export OPERATORS_NS="$(_o .namespaces.value.operators)"
export SA_CONTROL_PLANE="$(_o .service_accounts.value.control_plane)"
export SA_COMPUTE_PLANE="$(_o .service_accounts.value.compute_plane)"

# --- Karpenter ---------------------------------------------------------------------------------------
export KARPENTER_NODE_ROLE="$(_o .karpenter.value.node_role)"
export KARPENTER_QUEUE="$(_o .karpenter.value.queue_name)"
export KARPENTER_DISCOVERY_TAG="$(_o .karpenter.value.discovery_tag)"

# --- Backends ----------------------------------------------------------------------------------------
export PG_HOST="$(_o .postgresql.value.host)"
export PG_PORT="$(_o .postgresql.value.port)"
export PG_DATABASE="$(_o .postgresql.value.database)"
# Secrets Manager secret holding {"username", "password"}; ESO reads it
export PG_SECRET_ARN="$(_o .postgresql.value.secret_arn)"
export SQS_PREFIX="$(_o .queue.value.prefix)"
export S3_BUCKET="$(_o .object_storage.value.bucket)"

# --- Registries --------------------------------------------------------------------------------------
# One prefix per upstream registry; the values files append the image path to them. Default: the ECR
# pull-through cache of the quick deploy.
export REG_DOCKERHUB="$(_o .registry.value.upstreams.dockerHub)"
export REG_GHCR="$(_o .registry.value.upstreams.ghcr)"
export REG_QUAY="$(_o .registry.value.upstreams.quay)"
export REG_K8S="$(_o .registry.value.upstreams.k8s)"
export REG_ECR_PUBLIC="$(_o .registry.value.upstreams.ecrPublic)"
# Charts: the OCI prefix of `helm pull oci://<prefix>/<chart>`, one per upstream the charts come from
export CHARTS_DOCKERHUB="$REG_DOCKERHUB"
export CHARTS_ECR_PUBLIC="$REG_ECR_PUBLIC"
# The AWS Load Balancer Controller chart is on a classic HTTP Helm repository, not OCI
export EKS_CHARTS_URL="https://aws.github.io/eks-charts"

# Artifactory instead (path-based remote repositories, one per upstream, see docs/helm-cli.md):
# export ARTIFACTORY=artifactory.example.com
# export REG_DOCKERHUB=$ARTIFACTORY/docker-hub-remote
# export REG_GHCR=$ARTIFACTORY/ghcr-remote
# export REG_QUAY=$ARTIFACTORY/quay-remote
# export REG_K8S=$ARTIFACTORY/k8s-remote
# export REG_ECR_PUBLIC=$ARTIFACTORY/ecr-public-remote
# export CHARTS_DOCKERHUB=$ARTIFACTORY/dockerhub-helm-remote     # Helm OCI remote of registry-1.docker.io
# export CHARTS_ECR_PUBLIC=$ARTIFACTORY/ecr-public-helm-remote   # Helm OCI remote of public.ecr.aws
# export EKS_CHARTS_URL=https://$ARTIFACTORY/artifactory/api/helm/eks-helm-remote   # Helm remote of https://aws.github.io/eks-charts

# --- Customer Grafana ---------------------------------------------------------------------------------
# URL the ArmoniK ingress proxies /grafana/ to, reachable from the cluster. Empty: no /grafana route.
export GRAFANA_URL="${GRAFANA_URL:-}"

# --- Chart versions ----------------------------------------------------------------------------------
export KARPENTER_VERSION=1.14.1
export LBC_VERSION=3.5.0
export ARMONIK_VERSION=0.16.0-featexternalsto.301.sha.bf381bd3   # armonik and armonik-operators

# envsubst must only touch these: a value file may hold other $ signs
export ENVSUBST_VARS='${CLUSTER_NAME} ${AWS_REGION} ${VPC_ID} ${ARMONIK_NS} ${OPERATORS_NS} ${SA_CONTROL_PLANE}
${SA_COMPUTE_PLANE} ${KARPENTER_NODE_ROLE} ${KARPENTER_QUEUE} ${KARPENTER_DISCOVERY_TAG} ${PG_HOST} ${PG_PORT}
${PG_DATABASE} ${PG_SECRET_ARN} ${SQS_PREFIX} ${S3_BUCKET} ${REG_DOCKERHUB} ${REG_GHCR} ${REG_QUAY} ${REG_K8S}
${REG_ECR_PUBLIC} ${CHARTS_DOCKERHUB} ${CHARTS_ECR_PUBLIC} ${GRAFANA_URL}'

unset -f _o
unset _out _qd
