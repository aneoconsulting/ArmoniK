# GCP quick deploy with the ArmoniK Helm charts

One Terraform stack: GKE Standard with ComputeClasses (Spot workers), Artifact Registry pull-through caches for
every image, ArmoniK on Cloud SQL for PostgreSQL (Private Service Connect), GCS and Pub/Sub, through the
[ArmoniK.Infra GCP modules](https://github.com/aneoconsulting/ArmoniK.Infra) and the Helm charts.

## Setup

- `gcloud auth application-default login`
- `backend.tfbackend`: copy the `.example`, set an existing GCS bucket for the state.
- `terraform.tfvars`: copy the `.example`, set `project` (and `registry_credentials` against the rate limits).

## Deploy

```sh
terraform init -backend-config=backend.tfbackend
terraform apply
terraform output endpoints
```

The load balancer serves the API on 5001, and the GUI (`/admin/`), Grafana (`/grafana/`) and Seq (`/seq/`) on
5000, with no authentication: `ingress_allowed_cidrs` restricts who reaches it.

Never apply a change that replaces the cluster (zone, prefix, network ranges): the Kubernetes providers lose it while
its releases are still in the state. Destroy, then deploy again.

## Access

```sh
$(terraform output -raw kubeconfig_command)
export KUBECONFIG=$PWD/kubeconfig
```

## Add a partition

Push the image to a registry the nodes can pull (public, or Artifact Registry in the project), with a new tag for
every version, then declare it in `terraform.tfvars` (name: lowercase letters and digits) and apply:

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

The partition runs no pod until tasks arrive. Its pods run on Spot nodes: a preemption loses the running tasks,
which Core retries.

## Autoscaling

A partition scales on its queue length (the chart's trigger). With the laws on, it can select another one:

```hcl
autoscaling_laws = true

partitions = {
  myapp = {
    image       = "europe-west9-docker.pkg.dev/my-project/my-repo/my-worker"
    tag         = "1.0.0"
    autoscaling = { law = "model", hpa = "fast" }
  }
}
```

`model` sizes the pods on the flow of tasks, their duration and the queue. Both laws are Prometheus recording
rules, computed for every partition and shown in the Grafana dashboard "Bench - autoscaling" next to what the pods
did. The laws, their parameters, the mathematics and the bench that compares them on twin partitions:
[autoscaling/README.md](autoscaling/README.md).

## Test

```sh
GRPC=$(terraform output -json endpoints | jq -r .grpc)
docker run --rm -e HtcMock__NTasks=1000 -e HtcMock__TotalCalculationTime=00:00:00.100 -e HtcMock__SubTasksLevels=1 \
  -e HtcMock__Partition=htcmock -e GrpcClient__Endpoint=$GRPC \
  dockerhubaneo/armonik_core_htcmock_test_client:0.41.4
```

## Destroy

```sh
terraform destroy
# Topics and subscriptions Core created, outside the state (prefix: the prefix variable, armonik by default)
for s in $(gcloud pubsub subscriptions list --filter="name~/armonik-" --format="value(name)"); do gcloud pubsub subscriptions delete "$s"; done
for t in $(gcloud pubsub topics list --filter="name~/armonik-" --format="value(name)"); do gcloud pubsub topics delete "$t"; done
```

## PS: kubeconfig for kubie

Writes the kubeconfig to `generated/kubeconfig` (git-ignored), with the defaults `prefix = "armonik"` and
`zone = "europe-west9-a"`:

```sh
mkdir -p generated
env KUBECONFIG=generated/kubeconfig gcloud container clusters get-credentials armonik --dns-endpoint --location europe-west9-a --project <project>
```
