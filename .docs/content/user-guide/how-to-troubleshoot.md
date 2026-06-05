# Troubleshooting

This section covers the most common failure modes in ArmoniK deployments. Each section starts with the fastest diagnostic commands and then lists specific issues with targeted fixes.

All `kubectl` commands assume the `armonik` namespace. Add `-n armonik` or set your default namespace with `kubectl config set-context --current --namespace=armonik`.

---

## Quick first-pass diagnostics

Run these before diving into component-specific sections:

```bash
# Pod status overview — look for anything not Running or Completed
kubectl get pods -n armonik

# Events sorted by time — most useful for Pending or CrashLoopBackOff pods
kubectl get events -n armonik --sort-by='.lastTimestamp'

# Logs for a specific pod
kubectl logs -n armonik <pod-name> [--previous]

# Describe a pod — shows scheduling failures, volume mount errors, image pull errors
kubectl describe pod -n armonik <pod-name>
```

---

## Deployment start-up issues

### Component boot order

ArmoniK components have strict start-up dependencies. If something at the top of this chain is stuck, everything downstream will wait:

```
MongoDB (StatefulSet + Percona operator)
  └─> wait-for-percona-mongodb-db-ps (Job)
        └─> init (Job / CronJob)
              └─> control-plane
                    ├─> metrics-exporter
                    └─> compute-planes (polling-agent + worker)

Queue backend        ─┐
Object storage backend ─┼─> control-plane, compute-planes, metrics-exporter
MongoDB               ─┘
```

If any component is stuck, check the next item up the chain first.

### Secrets must exist before pods start

Three secrets are required by the control-plane, every compute-plane, and the metrics-exporter. All three are mounted as volumes with `optional: false` — if any of them are missing, those pods will stay in `ContainerCreating` indefinitely:

| Secret | Provides |
|---|---|
| Queue secret (`activemq`, `rabbitmq`, `sqs`, etc.) | Queue TLS/credentials bundle |
| `mongodb-db-ps-ssl` | MongoDB TLS certificate |
| Object storage secret (`redis`, etc.) | Object storage TLS/credentials bundle (absent for S3/GCS) |

```bash
# Check all three are present
kubectl get secrets -n armonik | grep -E "activemq|rabbitmq|mongodb-db-ps-ssl|redis"
```

### Expired TLS certificates (localhost deployments)

On localhost deployments, MongoDB and Redis certificates are generated with a short validity period (7 days by default in older versions). After expiry the deployment will fail silently.

**Fix:** destroy and redeploy. To avoid recurrence, set the certificate validity in `parameters.tfvars` before deploying:

```hcl
# infrastructure/quick-deploy/localhost/parameters.tfvars
# Set validity to 1 year
certificate_validity_period_hours = 8760
```

### Terraform interrupted mid-apply

Do **not** press `Ctrl+C` during a `terraform apply`. A second interrupt causes Terraform to exit without updating its state file, which leaves the state corrupted and requires manual repair. If you need to stop a long-running apply, wait for the current operation to finish or let it fail naturally.

---

## MongoDB

**Pod name:** `mongodb-db-ps-rs0-0` (StatefulSet)

| Symptom | Where to look |
|---|---|
| Pod stuck in `Pending` | PVC not bound — check `kubectl get pvc -n armonik`. The `local-path` StorageClass must be present on the cluster. |
| Pod in `CrashLoopBackOff` | Check logs for keyfile or SSL secret errors |
| Replica set not formed | Percona operator logs |
| TLS handshake failures | Secrets `mongodb-db-ps-ssl` and `mongodb-db-ps-ssl-internal` must exist and contain valid certs |

**Required secrets:**
- `mongodb-db-ps-mongodb-keyfile` — replica set auth keyfile
- `mongodb-db-ps-mongodb-encryption-key` — at-rest encryption key
- `mongodb-db-ps-ssl` — external TLS cert/key
- `mongodb-db-ps-ssl-internal` — internal cluster TLS
- `internal-mongodb-db-ps-users` — operator-managed credentials

```bash
kubectl describe statefulset mongodb-db-ps-rs0 -n armonik
kubectl logs -n armonik mongodb-db-ps-rs0-0
kubectl exec -n armonik mongodb-db-ps-rs0-0 -- mongo --eval "rs.status()"
kubectl get pvc -n armonik

# Percona operator logs (if replica set is not forming)
kubectl logs -n armonik deploy/mongodb-psmdb-operator
```

### PVC not bound

```bash
kubectl get pvc -n armonik
kubectl describe pvc mongod-data-mongodb-db-ps-rs0-0 -n armonik
kubectl get storageclass
```

The `local-path` StorageClass must be present. If it is missing, redeploy the local-path provisioner (bundled with k3s, or install it separately via Helm).

---

## init Job

The `init` job initialises database partitions and the queue and object storage backends. It runs once at deploy time and then runs every minute as a CronJob to keep partition config in sync. If it never completes, the control-plane will not start.

The job has a hard **2-minute Terraform timeout**. Any condition that prevents it from completing within that window causes `terraform apply` to fail, often with a generic timeout error rather than a root-cause message. When you see a Terraform timeout during apply, check the init job pod logs immediately — the real error is there.

| Symptom | Where to look |
|---|---|
| `terraform apply` times out during init | `kubectl logs -n armonik -l job-name=init` — look for connection errors to MongoDB, the queue, or object storage |
| Job `Failed` | Logs — usually a MongoDB connection error or missing credentials |
| Pod `Pending` forever | Node selector in `var.init.node_selector` has no matching nodes |
| `CreateContainerConfigError` | A referenced Secret or ConfigMap does not exist yet |
| CronJob not firing | Check the `Suspend` flag and last-schedule timestamp; also check `starting_deadline_seconds` — if the scheduler backlog exceeds 20 seconds, the CronJob is suspended |
| Both `var.init` and `var.job_partitions_in_database` set | No partitions written despite a successful-looking run — only one of these should be set at a time |

```bash
kubectl get jobs -n armonik
kubectl logs -n armonik -l job-name=init --tail=50
kubectl describe cronjob init -n armonik
```

---

## Control Plane

| Symptom | Where to look |
|---|---|
| Pod stuck in `ContainerCreating` | Queue secret, `mongodb-db-ps-ssl`, and object storage secret must all exist |
| Pod in `CrashLoopBackOff` | Logs — usually a connection failure to MongoDB, the queue, or object storage |
| `init` Job still incomplete | Control-plane will not become healthy until `init` finishes |

```bash
kubectl logs -n armonik deploy/control-plane [--previous]
kubectl describe deploy control-plane -n armonik
```

---

## Compute Planes (Worker pods)

Each compute plane pod runs two containers: **polling-agent** and **worker** (your application).

| Symptom | Where to look |
|---|---|
| Pod stuck in `ContainerCreating` | Same 3 secrets as control-plane must exist |
| `ImagePullBackOff` on worker | Verify the image tag exists on Docker Hub or your registry |
| Worker `CrashLoopBackOff` | Check worker container logs specifically (see commands below) |
| Polling agent cannot reach control-plane | Service `control-plane` on port `5001` must be reachable |
| Shared data directory missing | HostPath from `shared-storage` secret must exist on the host node |
| KEDA not scaling up | Check metrics-exporter health; check the HPA status |

```bash
# Logs from both containers
kubectl logs -n armonik <pod-name> --all-containers

# Separate containers
kubectl logs -n armonik <pod-name> -c polling-agent
kubectl logs -n armonik <pod-name> -c worker   # adjust name to your container

# KEDA HPA status
kubectl describe hpa -n armonik

# Check shared-storage HostPath exists on the host
HOST_PATH=$(kubectl get secret shared-storage -n armonik \
  -o jsonpath='{.data.host_path}' | base64 -d)
ls "$HOST_PATH"
```

---

## Tasks submitted but not processed

Work through these in order:

### 1. Set `MaxRetries = 1` in your task options

With retries enabled, the first error is swallowed and retried silently. Setting retries to 1 forces the client to receive the error message on the first failure.

### 2. Check Seq for worker logs

Open Seq (see [Logs & Debugging](../admin-ops/1.logs_debugging.md) for the URL). If no worker logs appear, either:
- Workers are scaled to zero — check KEDA HPA status
- You used the wrong partition name — verify the partition exists

### 3. Check for malfunctioning pods

```bash
kubectl get pods -n armonik
kubectl describe pod -n armonik <pod-name>
```

### 4. Check KEDA metrics

If workers are not scaling up, the metrics-exporter may be down:

```bash
kubectl logs -n armonik deploy/metrics-exporter
kubectl describe hpa -n armonik
```

KEDA HPAs showing `<unknown>` on every partition is expected when all partitions are idle (scaled to zero). The problem is if they still show `<unknown>` after tasks are submitted.

---

## Queue back-ends

The active queue adapter is declared in `core-configmap`:

```bash
kubectl get configmap core-configmap -n armonik \
  -o jsonpath='{.data.Components__QueueAdaptorSettings__AdapterAbsolutePath}'
```

### ActiveMQ / RabbitMQ (AMQP adapter)

Both use the same AMQP adapter and the same `Amqp__*` config keys.

| Symptom | Where to look |
|---|---|
| Pod `CrashLoopBackOff` | Certificate secret (`activemq-server-certificates`) must exist |
| Consumers cannot connect | Secrets `activemq-user-credentials` and `activemq-user-certificates` must exist |
| Downstream pods in `ContainerCreating` | Secret `activemq` (connection bundle volume) must exist |
| TLS errors in control-plane logs | `Amqp__Scheme` is `AMQPS` — verify `Amqp__CaPath` points to a valid CA in the mounted secret |
| Wrong host (RabbitMQ) | Confirm `Amqp__Host` points to the RabbitMQ service, not `activemq` |

```bash
kubectl logs -n armonik deploy/activemq
kubectl get secret activemq activemq-server-certificates activemq-user-credentials -n armonik
kubectl get configmap core-configmap -n armonik -o yaml | grep Amqp__
```

### Amazon SQS

No in-cluster broker — SQS is an external AWS managed service.

| Symptom | Where to look |
|---|---|
| Control-plane cannot enqueue | IAM permissions — service account needs `sqs:SendMessage`, `sqs:ReceiveMessage`, `sqs:DeleteMessage` |
| Queue not found | SQS queues must be pre-created; verify `SQS__PartitionId` matches the queue name prefix |
| Auth errors | If using a Kubernetes secret instead of IRSA, verify `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` are in the pod environment |

```bash
kubectl get configmap core-configmap -n armonik -o yaml | grep -i sqs
```

### Google Cloud Pub/Sub

No in-cluster broker — Pub/Sub is an external GCP managed service. There is no built-in Terraform module that auto-configures PubSub credentials — all configuration must be injected manually via `configurations.core` or `configurations.jobs` in `parameters.tfvars`.

| Symptom | Cause |
|---|---|
| `InitQueue` fails, Terraform times out after 2 minutes | PubSub credentials missing from `configurations.core` — the init job has no valid config to connect with |
| `403 PERMISSION_DENIED` on every retry (Workload Identity) | The init job's Kubernetes service account is missing the IAM binding annotation (`var.init.annotations`); the pod authenticates as the default compute SA which has no PubSub IAM |
| Silent auth failure → ADC fallback → `403` (JSON key) | `GOOGLE_APPLICATION_CREDENTIALS` env var path does not match the actual mount path of the key file secret |
| `InitQueue` fails with resource not found | Topics and subscriptions must be pre-created in the GCP project matching `PubSub__ProjectId`; ArmoniK cannot create them without `pubsub.topics.create` / `pubsub.subscriptions.create` IAM |
| Pod hangs → Terraform 2-minute timeout | Egress to `pubsub.googleapis.com:443` is blocked by a `NetworkPolicy` or node firewall rule |
| Infinite CronJob kill-restart loop, `InitQueue` never completes | Workload Identity token fetch on a cold pod takes > 1 minute; the CronJob `Replace` policy kills the running pod before init completes |

```bash
kubectl get configmap core-configmap -n armonik -o yaml | grep -i pubsub
kubectl describe serviceaccount -n armonik <control-plane-sa> | grep -i workload
```

---

## Object storage back-ends

The active adapter is declared in `core-configmap`:

```bash
kubectl get configmap core-configmap -n armonik \
  -o jsonpath='{.data.Components__ObjectStorageAdaptorSettings__AdapterAbsolutePath}'
```

### Redis

| Symptom | Where to look |
|---|---|
| Pod not starting | Secret `redis-server-certificates` must exist |
| Downstream pods in `ContainerCreating` | Secret `redis` (TLS bundle volume) must exist |
| Auth failures | Check secrets `redis-user`, `redis-user-credentials`, `redis-user-certificates` |
| TLS errors | `Redis__SslHost` must match the CN in the server cert; `Redis__CaPath` must point to the mounted CA |
| Results lost on restart | Redis is in-memory by default — enable persistence if durability is required |

```bash
kubectl logs -n armonik deploy/redis
kubectl get configmap core-configmap -n armonik -o yaml | grep Redis__
```

### Amazon S3

| Symptom | Where to look |
|---|---|
| Cannot write payloads | IAM permissions — needs `s3:PutObject`, `s3:GetObject`, `s3:DeleteObject` on the target bucket |
| Bucket not found | Bucket must be pre-created and match `S3__BucketName` |
| Auth errors | If using a Kubernetes secret instead of IRSA, verify `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` |

```bash
kubectl get configmap core-configmap -n armonik -o yaml | grep -i s3
```

### Google Cloud Storage (GCS)

At the moment of writting this guidelines, there is still no built-in Terraform module for GCS — credentials must be injected manually via `configurations.core` in `parameters.tfvars`. GCS uses its S3-compatible endpoint (`storage.googleapis.com`), so the same S3-style env vars apply, but with important differences from AWS S3 or Minio.

| Symptom | Cause |
|---|---|
| `InitObjectStorage` fails, Terraform times out after 2 minutes | GCS credentials missing from `configurations.core` — the init job has no valid config |
| `403 InvalidAccessKeyId` on every retry | GCS's S3-compatible endpoint only accepts **HMAC key pairs** (access key + secret). Providing a service account JSON key or bearer token instead always produces this error. Generate HMAC keys in the GCP console under _Cloud Storage → Settings → Interoperability_. |
| `400 InvalidRequest` on every retry | `must_force_path_style` is set to `true`. GCS uses virtual-hosted-style addressing (`bucket.storage.googleapis.com`), not path-style. Set `must_force_path_style = false`. |
| Bucket not found / `InitObjectStorage` fails | GCS buckets are external and must be pre-created. The init job cannot create a bucket without project-level `storage.buckets.create`, which is typically denied on managed GCP projects. |
| `403` on every bucket operation | The HMAC key's service account is missing `storage.objects.create`, `storage.objects.get`, or `storage.objects.delete` on the target bucket. |
| Pod hangs → Terraform 2-minute timeout | Egress to `storage.googleapis.com` is blocked by a `NetworkPolicy` or node firewall rule. |

```bash
kubectl get configmap core-configmap -n armonik -o yaml | grep -i gcs
# Verify HMAC key format (should show access key, not a JSON blob)
kubectl get secret <gcs-credentials-secret> -n armonik -o yaml
```

### Local / HostPath storage

| Symptom | Where to look |
|---|---|
| Pods fail to start | HostPath directory must exist on the node before the pod is scheduled |
| Data not accessible across nodes | HostPath is node-local — use NFS if pods span multiple nodes |
| Permission denied | Directory must be readable/writable by the container's UID |
| Worker libraries not found | The same HostPath mounts worker `.so`/DLL files — verify the data directory is populated |

```bash
kubectl get secret shared-storage -n armonik -o yaml
HOST_PATH=$(kubectl get secret shared-storage -n armonik \
  -o jsonpath='{.data.host_path}' | base64 -d)
ls "$HOST_PATH"
```

---

## Metrics Exporter

Exposes task metrics on port `9419` — used by both Prometheus and KEDA.

| Symptom | Where to look |
|---|---|
| Pod not starting | Same 3 required secrets as control-plane |
| KEDA HPAs show `<unknown>` after tasks are submitted | Metrics exporter is down or not returning data |
| Metrics missing in Prometheus | Service `metrics-exporter` on port `9419` must be reachable |

```bash
kubectl logs -n armonik deploy/metrics-exporter
kubectl get secret metrics-exporter -n armonik
```

---

## Ingress / nginx

| Symptom | Where to look |
|---|---|
| Pod not starting | ConfigMaps `nginx-conf` and `nginx-static` must exist |
| LoadBalancer IP not assigned | Check MetalLB or the underlying load balancer controller |
| gRPC connection refused from outside | Control-plane service on port `5001` must be healthy |

```bash
kubectl logs -n armonik deploy/nginx
kubectl describe svc nginx -n armonik
```

---

## Monitoring stack

### Seq (structured logs)

```bash
kubectl logs -n armonik deploy/seq
kubectl describe cronjob seq-retention-job -n armonik   # manages log retention
kubectl port-forward -n armonik svc/seq-web-console 8080:8080
```

| Symptom | Where to look |
|---|---|
| Pod not starting | Secret `seq` must exist |
| No logs ingested | Fluent Bit must be running and pointing to `seq:5341` |

### Prometheus

```bash
kubectl logs -n armonik deploy/prometheus
kubectl port-forward -n armonik svc/prometheus 9090:9090
# Then open http://localhost:9090/targets to check scrape status
```

| Symptom | Where to look |
|---|---|
| Missing ArmoniK task metrics | `metrics-exporter` on port `9419` must be up |

### Grafana

```bash
kubectl logs -n armonik deploy/grafana
```

| Symptom | Where to look |
|---|---|
| No data in dashboards | Prometheus service must be reachable at `prometheus:9090` |
| Login fails | Secret `grafana` (admin credentials) must exist |

### Fluent Bit

Fluent Bit runs as a DaemonSet (one pod per node).

```bash
kubectl logs -n armonik -l app=fluent-bit
kubectl describe daemonset fluent-bit -n armonik
```

| Symptom | Where to look |
|---|---|
| Logs not appearing in Seq | Check Fluent Bit logs for connection errors to `seq:5341` |
| Node-level permission error | Fluent Bit needs read access to host log directories (`/var/log`, `/var/lib/docker/containers`) |

---

## Force-deleting a stuck pod

If `kubectl delete pod` leaves a pod in `Terminating` for more than a few minutes:

```bash
kubectl delete pod -n armonik --force <pod-name>

# Confirm it is gone
kubectl get pod -n armonik --field-selector metadata.name=<pod-name>
```

Use this only as a last resort — force deletion skips graceful shutdown and can leave orphaned resources.

---

## Image pull failures

```bash
kubectl describe pod -n armonik <pod-name> | grep -A5 "Events:"
```

All ArmoniK images are published to Docker Hub under `dockerhubaneo/*`. Verify the exact tag you are deploying exists on Docker Hub. If you are behind a corporate proxy or air-gapped network, ensure the registry mirror is configured correctly.

---

## Finding the deployed URLs

After a successful deployment, the service URLs are printed to the console and stored in the Terraform output files:

```bash
# Admin GUI URL
cat armonik/generated/armonik-output.json | grep admin_gui_url

# Seq URL
cat monitoring/generated/monitoring-output.json | grep seq_web_url
```

Default ports: Admin GUI on `:5000`, Seq on `:8080`.
