# AWS quick deploy with the ArmoniK Helm charts

Terraform (`terraform/`) creates the AWS infrastructure: VPC, EKS, Karpenter IAM and interruption queue, RDS
PostgreSQL, S3, the ECR pull-through cache and the EKS Pod Identity roles. Everything in the cluster is then
installed with `helm`, from the values in `values/`: Cilium + Hubble, Karpenter, the operators, Envoy Gateway
(the only entry point) and ArmoniK on RDS, S3 and SQS.

- Diagrams: [what gets deployed](docs/diagrams/01-deployment.md), [from Terraform to the helm releases](docs/diagrams/02-pipeline.md)
- Reference (variables, Artifactory, customer choices, advice, known limits): [docs/reference.md](docs/reference.md)
- Hubble (what to watch during an htcmock run, filters): [docs/hubble.md](docs/hubble.md)

Requirements: `aws`, `terraform` >= 1.11, `helm` >= 3.8, `kubectl`, `jq`, `envsubst` (package `gettext`). Deploying
from AWX (Ansible) instead of a shell: see [docs/reference.md](docs/reference.md#running-from-awx).

## 0. Settings

```sh
export AWS_PROFILE=<profile> AWS_REGION=eu-west-3 PREFIX=armonik-demo   # PREFIX names every resource
cp backend.tfbackend.example backend.tfbackend                          # set the state bucket and its region
```

The infrastructure parameters are in `parameters.tfvars` (all of them in `terraform/variables.tf`).

## 1. Registry credentials

All images and charts are pulled through the ECR pull-through cache. AWS requires upstream credentials for
Docker Hub (a read-only access token) and GitHub (a classic token with `read:packages`):

```sh
cp registry-credentials.tfvars.example registry-credentials.tfvars   # git-ignored: fill in the two tokens
```

Terraform writes them to Secrets Manager, never to the state. Keep the file: `apply` and `destroy` read it.
To rotate a token, edit the file and bump `registry_credentials_version` in it.

**Artifactory instead.** The cache is still created (Terraform needs the credentials above) but stays unused.
In `values/env.sh`, replace the `REG_*`, `CHARTS_*` and `EKS_CHARTS_URL` lines by the commented Artifactory
block. In step 3, replace the `aws ecr get-login-password` line by:

```sh
helm registry login "$ARTIFACTORY" --username "$ARTIFACTORY_USER" --password-stdin <<< "$ARTIFACTORY_TOKEN"
for ns in kube-system envoy-gateway-system "$OPERATORS_NS" "$ARMONIK_NS"; do
  kubectl create namespace "$ns" --dry-run=client -o yaml | kubectl apply -f -
  kubectl create secret docker-registry registry-credentials -n "$ns" \
    --docker-server="$ARTIFACTORY" --docker-username="$ARTIFACTORY_USER" --docker-password="$ARTIFACTORY_TOKEN"
done
```

Uncomment the `imagePullSecrets` blocks of the values files and add `-f $V/armonik-registry-auth.yaml` to the
`armonik` release. Repositories to create: [docs/reference.md](docs/reference.md#artifactory).

## 2. Terraform

```sh
terraform -chdir=terraform init -backend-config=../backend.tfbackend \
  -backend-config="key=$PREFIX/armonik-terraform.tfstate"
terraform -chdir=terraform apply -var-file=../parameters.tfvars -var-file=../registry-credentials.tfvars \
  -var prefix="$PREFIX" -var region="$AWS_REGION"
```

## 3. Helm

```sh
source values/env.sh                       # variables from the Terraform outputs
mkdir -p generated/values && V=generated/values
for f in values/*.yaml; do envsubst "$ENVSUBST_VARS" < "$f" > "$V/$(basename "$f")"; done

export KUBECONFIG=$PWD/generated/kubeconfig
aws eks update-kubeconfig --name "$CLUSTER_NAME" --region "$AWS_REGION" --kubeconfig "$KUBECONFIG"
aws ecr get-login-password | helm registry login --username AWS --password-stdin "${REG_DOCKERHUB%%/*}"   # valid 12 h
helm repo add eks "$EKS_CHARTS_URL" && helm repo update eks

helm upgrade --install cilium "oci://$CHARTS_QUAY/cilium/charts/cilium" --version "$CILIUM_VERSION" \
  -n kube-system -f $V/cilium.yaml
kubectl -n kube-system rollout status ds/cilium   # Hubble relay and UI start later, on the first core node
helm upgrade --install karpenter "oci://$CHARTS_ECR_PUBLIC/karpenter/karpenter" --version "$KARPENTER_VERSION" \
  -n kube-system -f $V/karpenter.yaml --wait
helm upgrade --install karpenter-nodes ./charts/karpenter-nodes \
  -n kube-system -f $V/karpenter-nodes.yaml --wait
helm upgrade --install aws-load-balancer-controller eks/aws-load-balancer-controller --version "$LBC_VERSION" \
  -n kube-system -f $V/aws-load-balancer-controller.yaml --wait
helm upgrade --install armonik-operators "oci://$CHARTS_DOCKERHUB/dockerhubaneo/armonik-operators" --version "$ARMONIK_VERSION" \
  -n "$OPERATORS_NS" --create-namespace -f $V/armonik-operators.yaml --wait --timeout 10m
helm upgrade --install aws-secret-store ./charts/aws-secret-store \
  -n "$OPERATORS_NS" -f $V/aws-secret-store.yaml --wait
helm upgrade --install eg "oci://$CHARTS_DOCKERHUB/envoyproxy/gateway-helm" --version "$EG_VERSION" \
  -n envoy-gateway-system --create-namespace -f $V/envoy-gateway.yaml --wait
helm upgrade --install armonik "oci://$CHARTS_DOCKERHUB/dockerhubaneo/armonik" --version "$ARMONIK_VERSION" \
  -n "$ARMONIK_NS" --create-namespace -f $V/armonik.yaml --wait --timeout 15m
helm upgrade --install armonik-gateway ./charts/armonik-gateway \
  -n "$ARMONIK_NS" -f $V/armonik-gateway.yaml --wait
```

Keep the order: each release needs the previous ones. Never add `--reuse-values`, nor `--wait-for-jobs` (the
init Jobs delete themselves). Hardening: `-f $V/armonik-hardening.yaml` on `armonik` (NetworkPolicies), and
`loadBalancer.scheme: internal` and `tls` in `values/armonik-gateway.yaml`.

```sh
kubectl get svc -n envoy-gateway-system -l gateway.envoyproxy.io/owning-gateway-name=armonik   # the NLB
kubectl port-forward -n kube-system svc/hubble-ui 12000:80                                       # Hubble UI
```

The NLB serves the ArmoniK API and the GUI (`/admin/`) on 5001 and 5000, and Seq on 8080.

## 4. Test

The htcmock client, from any machine with Docker, through the NLB. Its image tag is the Core version of the release:

```sh
NLB=$(kubectl get svc -n envoy-gateway-system -l gateway.envoyproxy.io/owning-gateway-name=armonik \
  -o jsonpath='{.items[0].status.loadBalancer.ingress[0].hostname}')
CORE=$(helm get values armonik -n "$ARMONIK_NS" -o json | jq -r .global.armonik.versions.core)

docker run --rm \
  -e HtcMock__NTasks=2000 \
  -e HtcMock__TotalCalculationTime=02:00:00 \
  -e HtcMock__DataSize=1 -e HtcMock__MemorySize=1 \
  -e HtcMock__EnableFastCompute=false -e HtcMock__SubTasksLevels=1 \
  -e HtcMock__Partition=htcmock \
  -e GrpcClient__Endpoint=http://$NLB:5001 \
  dockerhubaneo/armonik_core_htcmock_test_client:$CORE
```

The client submits one root task, whose worker creates the `NTasks` subtasks: they reach the queue once their
payloads are in S3, then KEDA scales the `htcmock` partition (up to 50 pods) and Karpenter adds `workers` nodes.
Each task computes `TotalCalculationTime / NTasks` (here 3.6 s). To watch it:

```sh
kubectl get pods -n "$ARMONIK_NS" -l armonik.fr/partition=htcmock -w
kubectl get nodeclaims -w
```

Stopping the client does not stop the tasks: cancel or delete the session in the GUI. The partition scales back to 0
about 5 minutes after the queue is empty (KEDA cooldown).

## 5. Removal

Reverse order, waiting for the NLB and the Karpenter nodes, else `terraform destroy` fails on the VPC:

```sh
helm uninstall armonik-gateway armonik -n "$ARMONIK_NS" --wait
kubectl get svc -A | grep LoadBalancer                     # wait until empty
helm uninstall eg -n envoy-gateway-system
helm uninstall aws-secret-store armonik-operators -n "$OPERATORS_NS"
helm uninstall aws-load-balancer-controller -n kube-system
kubectl delete nodepools.karpenter.sh --all
kubectl get nodeclaims.karpenter.sh                        # wait until empty
helm uninstall karpenter-nodes karpenter cilium -n kube-system

terraform -chdir=terraform destroy -var-file=../parameters.tfvars -var-file=../registry-credentials.tfvars \
  -var prefix="$PREFIX" -var region="$AWS_REGION"

# Repositories created by the pull-through cache, outside the Terraform state
for repo in $(aws ecr describe-repositories --output text \
    --query "repositories[?starts_with(repositoryName, '$PREFIX/')].repositoryName"); do
  aws ecr delete-repository --repository-name "$repo" --force > /dev/null && echo "deleted $repo"
done
```
