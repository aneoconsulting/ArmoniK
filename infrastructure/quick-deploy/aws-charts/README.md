# AWS quick deploy with the ArmoniK Helm charts, through helmfile

Terraform (`terraform/`) creates the AWS infrastructure: VPC, EKS, Karpenter IAM and interruption queue, RDS
PostgreSQL, S3, the ECR pull-through cache and the EKS Pod Identity roles. Everything in the cluster is then
installed by [helmfile](https://helmfile.readthedocs.io/) (`helmfile.yaml.gotmpl`) from the Terraform outputs:
Cilium + Hubble, Karpenter, the operators, Envoy Gateway (the only entry point) and ArmoniK on RDS, S3 and SQS.

- Diagrams: [what gets deployed](docs/diagrams/01-deployment.md), [from Terraform to the helm releases](docs/diagrams/02-pipeline.md)
- Reference (settings, Artifactory, customer choices, advice, known limits): [docs/reference.md](docs/reference.md)

Requirements: `aws`, `terraform` >= 1.11, `helm` >= 3.8, `helmfile` >= 1.0 with the
[helm-diff](https://github.com/databus23/helm-diff) plugin, `kubectl`, `jq`. Deploying from AWX (Ansible) instead of a
shell: see [docs/reference.md](docs/reference.md#running-from-awx).

## 0. Settings

```sh
export AWS_PROFILE=<profile> AWS_REGION=eu-west-3 PREFIX=armonik-demo   # PREFIX names every resource
cp backend.tfbackend.example backend.tfbackend                          # set the state bucket and its region
```

The infrastructure parameters are in `parameters.tfvars` (all of them in `terraform/variables.tf`). What helmfile
deploys beyond the Terraform outputs (chart versions, registries, hardening) is in `values/settings.yaml`.

## 1. Registry credentials

All images and charts are pulled through the ECR pull-through cache. AWS requires upstream credentials for
Docker Hub (a read-only access token) and GitHub (a classic token with `read:packages`):

```sh
cp registry-credentials.tfvars.example registry-credentials.tfvars   # git-ignored: fill in the two tokens
```

Terraform writes them to Secrets Manager, never to the state. Keep the file: `apply` and `destroy` read it.
To rotate a token, edit the file and bump `registry_credentials_version` in it.

**Artifactory instead.** The cache is still created (Terraform needs the credentials above) but stays unused.
In `values/settings.yaml`, fill in `registries` and `charts` (commented blocks) and set `registryAuth: true`. In step
3, replace the `aws ecr get-login-password` line by:

```sh
helm registry login "$ARTIFACTORY" --username "$ARTIFACTORY_USER" --password-stdin <<< "$ARTIFACTORY_TOKEN"
for ns in kube-system envoy-gateway-system armonik-operators armonik; do
  kubectl create namespace "$ns" --dry-run=client -o yaml | kubectl apply -f -
  kubectl create secret docker-registry registry-credentials -n "$ns" \
    --docker-server="$ARTIFACTORY" --docker-username="$ARTIFACTORY_USER" --docker-password="$ARTIFACTORY_TOKEN"
done
```

Repositories to create: [docs/reference.md](docs/reference.md#artifactory).

## 2. Terraform

```sh
terraform -chdir=terraform init -backend-config=../backend.tfbackend \
  -backend-config="key=$PREFIX/armonik-terraform.tfstate"
terraform -chdir=terraform apply -var-file=../parameters.tfvars -var-file=../registry-credentials.tfvars \
  -var prefix="$PREFIX" -var region="$AWS_REGION"
```

## 3. Helmfile

```sh
mkdir -p generated
terraform -chdir=terraform output -json | jq 'map_values(.value)' > generated/armonik-output.json   # helmfile's input

export KUBECONFIG=$PWD/generated/kubeconfig
aws eks update-kubeconfig --name "$(jq -r .eks.name generated/armonik-output.json)" --kubeconfig "$KUBECONFIG"
aws ecr get-login-password | helm registry login --username AWS --password-stdin \
  "$(jq -r .registry.host generated/armonik-output.json)"                                        # valid 12 h

helmfile diff     # optional: what would change
helmfile apply    # the 9 releases, in order
```

helmfile installs, each release after the ones it `needs`: cilium, karpenter, karpenter-nodes,
aws-load-balancer-controller, armonik-operators, aws-secret-store, eg (Envoy Gateway), armonik, armonik-gateway.
Cilium is not waited for (Hubble starts on the first core node, once Karpenter runs): a hook waits for its agents.
One release only: `helmfile apply --selector name=armonik`. Hardening (NetworkPolicies, internal NLB, TLS):
`hardening: true` in `values/settings.yaml`.

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
CORE=$(helm get values armonik -n armonik -o json | jq -r .global.armonik.versions.core)

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
kubectl get pods -n armonik -l armonik.fr/partition=htcmock -w
kubectl get nodeclaims -w
```

Stopping the client does not stop the tasks: cancel or delete the session in the GUI. The partition scales back to 0
about 5 minutes after the queue is empty (KEDA cooldown).

## 5. Removal

Reverse order, waiting for the NLB and the Karpenter nodes, else `terraform destroy` fails on the VPC:

```sh
helmfile destroy --selector name=armonik-gateway
helmfile destroy --selector name=armonik
kubectl get svc -A | grep LoadBalancer                     # wait until empty
helmfile destroy --selector name=eg
helmfile destroy --selector name=aws-secret-store
helmfile destroy --selector name=armonik-operators
helmfile destroy --selector name=aws-load-balancer-controller
kubectl delete nodepools.karpenter.sh --all
kubectl get nodeclaims.karpenter.sh                        # wait until empty
helmfile destroy --selector name=karpenter-nodes
helmfile destroy --selector name=karpenter
helmfile destroy --selector name=cilium

terraform -chdir=terraform destroy -var-file=../parameters.tfvars -var-file=../registry-credentials.tfvars \
  -var prefix="$PREFIX" -var region="$AWS_REGION"

# Repositories created by the pull-through cache, outside the Terraform state
for repo in $(aws ecr describe-repositories --output text \
    --query "repositories[?starts_with(repositoryName, '$PREFIX/')].repositoryName"); do
  aws ecr delete-repository --repository-name "$repo" --force > /dev/null && echo "deleted $repo"
done
```
