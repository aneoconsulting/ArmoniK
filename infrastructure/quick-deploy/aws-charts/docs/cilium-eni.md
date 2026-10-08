# Cilium instead of the VPC CNI and kube-proxy

By default Cilium is chained on the AWS VPC CNI (`values/cilium.yaml`): the VPC CNI gives the pods their IP
addresses, kube-proxy handles the Services, and Cilium only enforces the NetworkPolicies and runs Hubble. This
page replaces both: Cilium in ENI mode allocates the pod IP addresses itself and replaces kube-proxy with eBPF.

It is written for a cluster where `terraform apply` has run but no helm release is installed yet (README step 3
not started). The only nodes are then those of the `system` managed node group, nothing else to migrate.

| | Chained (default) | ENI mode |
|---|---|---|
| Pod IP addresses | VPC CNI, from the VPC | Cilium operator, from the VPC (still VPC addresses) |
| Services | kube-proxy (iptables) | Cilium (eBPF, `kubeProxyReplacement`) |
| EKS add-ons | `vpc-cni`, `kube-proxy` | none of the two |
| AWS rights | none for Cilium | Cilium operator creates and attaches ENIs (Pod Identity) |
| Security groups for pods | Possible (VPC CNI feature) | Not available: the ENIs take the security groups of the node's primary ENI |
| Cilium Gateway API / Ingress | Not available | Available, but left off: Envoy Gateway stays the entry point |

Unchanged: the NLB in `ip` target mode, Pod Identity (agent on the host network, `169.254.170.23`), RDS reached
from the node security group, Envoy Gateway, the Karpenter startup taint.

## 1. Terraform

**`terraform/eks.tf`**: drop the `vpc-cni` and `kube-proxy` add-ons.

```hcl
  addons = {
    eks-pod-identity-agent = { before_compute = true }
    # Tolerates CriticalAddonsOnly by default, so it lands on the system nodes
    coredns = {}
    aws-ebs-csi-driver = {
      ...
    }
  }
```

Optional, same file: give the `system` node group the taint Karpenter nodes already have, so no pod starts on a
node before the Cilium agent is ready. Changing taints updates the node group in place.

```hcl
      taints = {
        critical = { ... }
        cilium = {
          key    = "node.cilium.io/agent-not-ready"
          value  = "true"
          effect = "NO_EXECUTE"
        }
      }
```

`bootstrap_self_managed_addons` needs no change: module `eks` v21 already sets it to `false`.

**`terraform/identities.tf`**: rights of the Cilium operator, which manages the ENIs. Check the list against the
ENI IAM page of the Cilium docs for the version in `CILIUM_VERSION`.

```hcl
# Cilium operator (ENI mode): creates and attaches the ENIs and assigns the pod IP addresses
data "aws_iam_policy_document" "cilium_operator" {
  statement {
    sid = "Eni"
    actions = [
      "ec2:CreateNetworkInterface",
      "ec2:AttachNetworkInterface",
      "ec2:DetachNetworkInterface",
      "ec2:DeleteNetworkInterface",
      "ec2:ModifyNetworkInterfaceAttribute",
      "ec2:AssignPrivateIpAddresses",
      "ec2:UnassignPrivateIpAddresses",
      "ec2:CreateTags",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DescribeInstances",
      "ec2:DescribeInstanceTypes",
      "ec2:DescribeSubnets",
      "ec2:DescribeVpcs",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeRouteTables",
      "ec2:DescribeTags",
    ]
    resources = ["*"]
  }
}

module "cilium_operator_identity" {
  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "~> 2.9"

  name            = "${local.name}-cilium-operator"
  use_name_prefix = false

  attach_custom_policy    = true
  source_policy_documents = [data.aws_iam_policy_document.cilium_operator.json]

  associations = {
    operator = {
      cluster_name    = module.eks.cluster_name
      namespace       = "kube-system"
      service_account = "cilium-operator"
    }
  }
}
```

**`terraform/outputs.tf`**: add the VPC CIDR to the `eks` output (`endpoint` is already there).

```hcl
    vpc_cidr = module.vpc.vpc_cidr_block
```

Then:

```sh
terraform -chdir=terraform apply -var-file=../parameters.tfvars -var-file=../registry-credentials.tfvars \
  -var prefix="$PREFIX" -var region="$AWS_REGION"
```

## 2. Remove what the add-ons leave behind

The module deletes add-ons with `preserve = true`: the DaemonSets stay in the cluster and must be deleted by hand.

```sh
export KUBECONFIG=$PWD/generated/kubeconfig
kubectl -n kube-system delete ds aws-node kube-proxy
kubectl -n kube-system delete cm kube-proxy kube-proxy-config --ignore-not-found
```

From here until Cilium runs, new pods cannot get an IP address. Running pods keep theirs.

## 3. Values

**`values/env.sh`**: two variables, under `# --- EKS`, and both added to `ENVSUBST_VARS`.

```sh
export VPC_CIDR="$(_o .eks.value.vpc_cidr)"
# API server host for Cilium: without kube-proxy, the agents cannot use the kubernetes Service to reach it
export EKS_ENDPOINT_HOST="$(_o .eks.value.endpoint | sed 's|^https://||')"
```

```sh
export ENVSUBST_VARS='${CLUSTER_NAME} ${AWS_REGION} ${VPC_ID} ${VPC_CIDR} ${EKS_ENDPOINT_HOST} ...'
```

**`values/cilium.yaml`**: replace the chaining block (`cni`, `enableIPv4Masquerade`, `routingMode`,
`endpointRoutes`) with the one below. Images, operator tolerations and Hubble stay as they are.

```yaml
# Cilium in ENI mode: the operator attaches ENIs to the nodes and gives the pods VPC addresses (so the NLB with
# nlb-target-type ip and Pod Identity are untouched), and Cilium replaces kube-proxy. No vpc-cni nor kube-proxy
# add-on (terraform/eks.tf). The operator's AWS rights come from Pod Identity (terraform/identities.tf).
ipam:
  mode: eni
eni:
  enabled: true
  # More pods per node: one /28 prefix per ENI slot. Set kubelet maxPods on the Karpenter EC2NodeClass then.
  # awsEnablePrefixDelegation: true
routingMode: native
# Not masqueraded inside the VPC (RDS, VPC endpoints see the pod address), masqueraded to the node beyond (NAT)
ipv4NativeRoutingCIDR: "${VPC_CIDR}"
enableIPv4Masquerade: true
bpf:
  masquerade: true
kubeProxyReplacement: true
k8sServiceHost: "${EKS_ENDPOINT_HOST}"
k8sServicePort: 443
cni:
  # Cilium is the only CNI: it moves any other configuration out of /etc/cni/net.d
  exclusive: true
# Envoy Gateway is the entry point: Cilium's own Gateway API and Ingress stay off (chart defaults)
```

The operator runs on the host network, so it starts before any CNI and reaches the Pod Identity agent.

## 4. Install Cilium

The first commands of README step 3, unchanged:

```sh
source values/env.sh
mkdir -p generated/values && V=generated/values
for f in values/*.yaml; do envsubst "$ENVSUBST_VARS" < "$f" > "$V/$(basename "$f")"; done

helm upgrade --install cilium "oci://$CHARTS_QUAY/cilium/charts/cilium" --version "$CILIUM_VERSION" \
  -n kube-system -f $V/cilium.yaml
kubectl -n kube-system rollout status ds/cilium
```

## 5. Replace the system nodes

They still hold the VPC CNI configuration and ENIs and the kube-proxy iptables rules. Nothing runs on them but
CoreDNS and the add-ons, so terminate them all; the node group's Auto Scaling group starts new ones, which come
up with Cilium only.

```sh
ids=$(kubectl get nodes -l armonik.aneo.fr/node-group=system -o jsonpath='{.items[*].spec.providerID}' \
  | tr ' ' '\n' | awk -F/ '{print $NF}')
aws ec2 terminate-instances --instance-ids $ids
kubectl get nodes -w                         # wait for the new nodes to be Ready
```

## 6. Check

```sh
kubectl -n kube-system exec ds/cilium -- cilium-dbg status | grep -E 'KubeProxyReplacement|IPAM'
kubectl -n kube-system get ds aws-node kube-proxy   # NotFound for both
kubectl get pods -A -o wide                         # pod IPs in the private subnets of the VPC
cilium connectivity test                            # with the cilium CLI, optional
```

Then go on with README step 3 from the `karpenter` release. Karpenter nodes start with Cilium directly.

## Docs to update

- `docs/reference.md`: the paragraph saying Cilium is chained on the VPC CNI, and the Cilium row of the custom
  choices.
- `values/cilium.yaml`: the header comment describes the chaining.
- `terraform/vpc.tf`, `terraform/rds.tf`: comments mentioning the VPC CNI (the behaviour does not change).

## Deploying from an empty account

The steps above work because CoreDNS and the EBS CSI add-ons already exist when the CNI goes away. On a first
`terraform apply` without `vpc-cni`, the `system` nodes stay NotReady until Cilium is installed, so these two
add-ons never become ACTIVE and the apply times out. Either apply twice (first without `coredns` and
`aws-ebs-csi-driver`, then `helm install cilium`, then with them), or install Cilium from Terraform (`helm_release`)
between the cluster and these add-ons.
