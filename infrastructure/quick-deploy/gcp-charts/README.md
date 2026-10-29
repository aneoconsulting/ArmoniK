# GCP quick deploy with the ArmoniK Helm charts

GKE Standard, ArmoniK on PostgreSQL (CloudNativePG, in the cluster), GCS and Pub/Sub. `terraform/gcp` creates the
GCP resources with the [ArmoniK.Infra GCP modules](https://github.com/aneoconsulting/ArmoniK.Infra), then
`terraform/k8s` the Helm releases.

## Setup

- `gcloud auth application-default login`
- `terraform/backend.tfbackend`: copy the `.example`, set an existing GCS bucket for the states.
- `terraform/gcp/terraform.tfvars`: copy the `.example`, set `project`.

## Deploy

```sh
cd terraform/gcp
terraform init -backend-config=../backend.tfbackend
terraform apply

cd ../k8s
terraform init -backend-config=../backend.tfbackend
terraform apply -var-file=../backend.tfbackend   # finds the state of terraform/gcp
terraform output endpoints
```

The load balancer serves the API on 5001, and the GUI (`/admin/`), Grafana (`/grafana/`) and Seq (`/seq/`) on
5000, with no authentication: `ingress_allowed_cidrs` (`terraform/k8s/terraform.tfvars`) restricts who reaches it.

## Access

From `gcp-charts/`, write the kubeconfig to `./kubeconfig` (git-ignored):

```sh
$(terraform -chdir=terraform/gcp output -raw kubeconfig_command)
```

## Add a partition

Push the image to a registry the nodes can pull (public, or Artifact Registry in the project), with a new tag
for every version, then declare it in `terraform/k8s/terraform.tfvars` (name: lowercase letters and digits):

```hcl
partitions = {
  myapp = {
    image  = "europe-west9-docker.pkg.dev/my-project/my-repo/my-worker"   # without the tag
    tag    = "1.0.0"
    cpu    = "2"        # worker requests = limits
    memory = "4Gi"
  }
}
```

and apply `terraform/k8s` again. The partition runs no pod until tasks arrive.

## Test

```sh
GRPC=$(terraform -chdir=terraform/k8s output -json endpoints | jq -r .grpc)
docker run --rm -e HtcMock__NTasks=1000 -e HtcMock__TotalCalculationTime=00:00:00.100 -e HtcMock__SubTasksLevels=1 \
  -e HtcMock__Partition=htcmock -e GrpcClient__Endpoint=$GRPC \
  dockerhubaneo/armonik_core_htcmock_test_client:0.41.3
```

## Destroy

```sh
cd terraform/k8s
terraform destroy -var-file=../backend.tfbackend
gcloud compute forwarding-rules list   # wait until the load balancer of the ingress is gone

cd ../gcp
terraform destroy
# Topics and subscriptions Core created, outside the state (prefix: the prefix variable, armonik by default)
for s in $(gcloud pubsub subscriptions list --filter="name~/armonik-" --format="value(name)"); do gcloud pubsub subscriptions delete "$s"; done
for t in $(gcloud pubsub topics list --filter="name~/armonik-" --format="value(name)"); do gcloud pubsub topics delete "$t"; done
```
