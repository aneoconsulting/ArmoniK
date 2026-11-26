# GCP quick deploy with the ArmoniK Helm charts

## Deployed by default

| | |
|---|---|
| Cluster | GKE in europe-west9, system pool e2-standard-2, ComputeClasses `default` (n2d/e2, 2 cores min) and `workers` (spot c4/n2/n2d-standard-8) |
| Network | VPC with Cloud NAT, load balancer on `ingress_allowed_cidrs` |
| Storage | Cloud SQL PostgreSQL ENTERPRISE db-custom-2-8192 zonal 20 GB, GCS, Pub/Sub |
| ArmoniK | chart 0.17.1, Core 0.41.4, chart sizing (1 control plane, 1 ingress), Prometheus, Grafana, Seq |
| Partitions | `default`, `stream`, `htcmock` (scale to zero) and those of `gcp.tfvars` |

## Stack overrides

| | armonik69 (bench) | montparnasse |
|---|---|---|
| Region | default | us-central1 |
| Core | 0.41.5-SNAPSHOT.27 | default |
| Sizing | `armonik_values`: 4 control planes and 2 ingresses (1 CPU, 500m), logs at Warning; `operators_values`: Prometheus 2 CPU / 8 Gi, 3 days; `default` class 4 cores min | default |
| Cloud SQL | ENTERPRISE_PLUS db-perf-optimized-N-32, 400 GB, managed pooling | default |
| Partitions | bench workers, fixed pod count | `cpu` PymoniK worker (1 CPU, 2Gi, 8-48 pods) |

## armonik69

```sh
terraform init -reconfigure -backend-config=stacks/armonik69/gcp.tfbackend
terraform apply -var-file=stacks/armonik69/gcp.tfvars
```

## montparnasse

```sh
terraform init -reconfigure -backend-config=stacks/montparnasse/gcp.tfbackend
terraform apply -var-file=stacks/montparnasse/gcp.tfvars -target=google_artifact_registry_repository.images

../../../../MontparnasseAgent/deploy/images/build.sh cpu
gcloud auth configure-docker us-central1-docker.pkg.dev
docker tag pymonik-worker:cpu us-central1-docker.pkg.dev/<project>/montparnasse-images/pymonik-worker:cpu-0.1.0
docker push us-central1-docker.pkg.dev/<project>/montparnasse-images/pymonik-worker:cpu-0.1.0

terraform apply -var-file=stacks/montparnasse/gcp.tfvars
```

## Destroy

```sh
# armonik69 (montparnasse: the same with stacks/montparnasse)
terraform init -reconfigure -backend-config=stacks/armonik69/gcp.tfbackend
# Bucket with millions of objects: keep it out of the destroy, its 1-day lifecycle rule empties it
terraform state rm module.object_storage.google_storage_bucket.gcs
terraform destroy -var-file=stacks/armonik69/gcp.tfvars
# The day after
gcloud storage buckets delete gs://<prefix>-objects-<suffix>
```

## HtcMock

```sh
podman run --rm \
  -e GrpcClient__Endpoint=http://$(kubectl -n armonik get svc armonik-ingress -o jsonpath='{.status.loadBalancer.ingress[0].ip}'):5001 \
  -e HtcMock__Partition=htcmock \
  docker.io/dockerhubaneo/armonik_core_htcmock_test_client:0.41.4
```
