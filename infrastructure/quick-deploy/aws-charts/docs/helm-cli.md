# Deploying the charts with helm only

The helmfile only orders the releases and fills the values from the Terraform outputs. The same
deployment with plain `helm`, once `make apply output kubeconfig` has run:

## 1. Values

The files in `values/` are templates reading `generated/armonik-output.json`. Either render them once
with helmfile:

```sh
helmfile --file helmfile.yaml.gotmpl write-values \
  --output-file-template 'generated/values/{{ .Release.Name }}.yaml'
```

or copy them and replace each `{{ ... }}` by the matching Terraform output
(`jq . generated/armonik-output.json`).

## 2. Registry login

Charts and images come through the ECR pull-through cache:

```sh
REGISTRY=$(jq -r .registry.host generated/armonik-output.json)
DOCKER_HUB=$(jq -r .registry.upstreams.dockerHub generated/armonik-output.json)
ECR_PUBLIC=$(jq -r .registry.upstreams.ecrPublic generated/armonik-output.json)
OPERATORS_NS=$(jq -r .namespaces.operators generated/armonik-output.json)
ARMONIK_NS=$(jq -r .namespaces.armonik generated/armonik-output.json)
ARMONIK_VERSION=0.16.0-featpostgresmig.296.sha.67d6b6e4   # as pinned in helmfile.yaml.gotmpl

aws ecr get-login-password | helm registry login --username AWS --password-stdin "$REGISTRY"
helm repo add eks https://aws.github.io/eks-charts
```

## 3. Releases, in this order

Each release needs the previous one to be ready, hence `--wait`.

```sh
V=generated/values

# Karpenter, then its EC2NodeClass and NodePools (the CRDs come with the first chart)
helm upgrade --install karpenter "oci://$ECR_PUBLIC/karpenter/karpenter" --version 1.14.1 \
  -n kube-system -f $V/karpenter.yaml --wait
helm upgrade --install karpenter-nodes ./charts/karpenter-nodes \
  -n kube-system -f $V/karpenter-nodes.yaml --wait

# NLB for the ingress Service
helm upgrade --install aws-load-balancer-controller eks/aws-load-balancer-controller --version 3.5.0 \
  -n kube-system -f $V/aws-load-balancer-controller.yaml --wait

# Install-once operators (ESO, KEDA, cert-manager, kube-prometheus-stack)
helm upgrade --install armonik-operators "oci://$DOCKER_HUB/dockerhubaneo/armonik-operators" \
  --version "$ARMONIK_VERSION" -n "$OPERATORS_NS" --create-namespace -f $V/armonik-operators.yaml --wait

# ClusterSecretStore on AWS Secrets Manager (needs the ESO CRDs)
helm upgrade --install aws-secret-store ./charts/aws-secret-store \
  -n "$OPERATORS_NS" -f $V/aws-secret-store.yaml --wait

# ArmoniK
helm upgrade --install armonik "oci://$DOCKER_HUB/dockerhubaneo/armonik" \
  --version "$ARMONIK_VERSION" -n "$ARMONIK_NS" --create-namespace -f $V/armonik.yaml \
  --wait --timeout 15m   # no --wait-for-jobs: the init Jobs delete themselves 1s after completing
```

## Removal

In reverse order, waiting for the NLB to disappear after `armonik`, and for the Karpenter nodes
after deleting the NodePools, before removing their controllers: `make charts-destroy` scripts it.

```sh
helm uninstall armonik -n "$ARMONIK_NS" --wait
kubectl get svc -A | grep LoadBalancer          # wait until empty
helm uninstall aws-secret-store -n "$OPERATORS_NS"
helm uninstall armonik-operators -n "$OPERATORS_NS"
helm uninstall aws-load-balancer-controller -n kube-system
kubectl delete nodepools.karpenter.sh --all
kubectl get nodeclaims.karpenter.sh             # wait until empty
helm uninstall karpenter-nodes karpenter -n kube-system
```
