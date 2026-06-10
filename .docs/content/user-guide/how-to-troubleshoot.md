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
# Check all three are present — expect one line per matching secret name.
# If a secret you rely on (e.g. activemq, mongodb-db-ps-ssl) is missing from
# the output, the pods that mount it will be stuck in ContainerCreating.
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
# Shows the StatefulSet's desired vs ready replica count and recent events —
# look for scheduling or volume errors at the bottom of the output.
kubectl describe statefulset mongodb-db-ps-rs0 -n armonik

# Tails the MongoDB container logs — expect normal startup messages ending
# with "Waiting for connections". Keyfile/SSL errors will appear here.
kubectl logs -n armonik mongodb-db-ps-rs0-0

# Connects to the local mongod and prints the replica set status — expect a
# JSON document with one member in state PRIMARY (or SECONDARY for replicas).
kubectl exec -n armonik mongodb-db-ps-rs0-0 -- mongo --eval "rs.status()"

# Lists PersistentVolumeClaims — the MongoDB PVC(s) should show STATUS Bound.
kubectl get pvc -n armonik

# Percona operator logs (if replica set is not forming) — expect reconcile
# messages; errors here usually point to RBAC or CR validation issues.
kubectl logs -n armonik deploy/mongodb-psmdb-operator
```

### PVC not bound

```bash
# Lists all PVCs and their status — a PVC stuck in Pending means no
# StorageClass could provision (or no matching PV is available).
kubectl get pvc -n armonik

# Shows events for the MongoDB data PVC — look for "waiting for first
# consumer" or provisioner errors at the bottom.
kubectl describe pvc mongod-data-mongodb-db-ps-rs0-0 -n armonik

# Lists available StorageClasses — expect "local-path" to be present,
# with one of them marked (default).
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
# Lists Jobs and their completion status — the init Job should show
# COMPLETIONS 1/1. A CronJob-spawned job in progress shows 0/1.
kubectl get jobs -n armonik

# Last 50 lines of the init job's logs — expect "Done" or similar success
# messages at the end. Connection errors to MongoDB/queue/storage appear here.
kubectl logs -n armonik -l job-name=init --tail=50

# Shows the CronJob's schedule, suspend status, and last/next schedule
# times — useful to confirm it isn't suspended or stuck on a backlog.
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
# Tails the control-plane container logs — expect gRPC server startup
# messages and "listening on" lines. Use --previous to see the logs of a
# crashed container after a restart.
kubectl logs -n armonik deploy/control-plane [--previous]

# Shows the Deployment's replica status and recent events — expect
# READY 1/1 (or your configured replica count) with no warning events.
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
| No pods at all for a partition | The partition is missing from `compute_plane` in `parameters.tfvars`, or `min_replicas`/`replicas` are both `0` and no tasks have been submitted yet to trigger scale-up |

```bash
# Logs from both containers, interleaved — expect polling-agent logs
# showing it picking up tasks and worker logs showing task execution.
kubectl logs -n armonik <pod-name> --all-containers

# Separate containers
# polling-agent: expect repeated "polling for task" / task acquisition logs.
kubectl logs -n armonik <pod-name> -c polling-agent
# worker: expect your application's own startup and per-task logs.
kubectl logs -n armonik <pod-name> -c worker   # adjust name to your container

# KEDA HPA status — expect TARGETS showing current/target values and
# REPLICAS scaling between minReplicaCount and maxReplicaCount as tasks arrive.
kubectl describe hpa -n armonik

# Check shared-storage HostPath exists on the host — decodes the host
# path from the secret, then lists it; expect worker library files
# (.so/.dll) and any shared data to be present.
HOST_PATH=$(kubectl get secret shared-storage -n armonik \
  -o jsonpath='{.data.host_path}' | base64 -d)
ls "$HOST_PATH"
```

---

## Tasks submitted but not processed

Work through these in order:

### 1. Set `MaxRetries = 1` in your task options

With retries enabled, the first error is swallowed and retried silently. Setting retries to 1 forces the client to receive the error message on the first failure.

### 2. Check the worker logs

On a localhost/on-premise deployment, open Seq (see [Logs & Debugging](../admin-ops/1.logs_debugging.md) for the URL). On a cloud deployment, check the log aggregation service configured for the cluster instead (e.g. CloudWatch Logs on AWS, Cloud Logging on GCP). If no worker logs appear, either:
- Workers are scaled to zero — check KEDA HPA status
- You used the wrong partition name — verify the partition exists

### 3. Check for malfunctioning pods

```bash
# Pod status overview — expect all compute-plane pods Running with all
# containers Ready. Anything in CrashLoopBackOff or Pending needs investigation.
kubectl get pods -n armonik

# Describe a specific pod — check the Events section at the bottom for
# scheduling failures, image pull errors, or failed readiness probes.
kubectl describe pod -n armonik <pod-name>
```

### 4. Check KEDA metrics

If workers are not scaling up, the metrics-exporter may be down:

```bash
# Tails metrics-exporter logs — expect periodic scrape/serve messages with
# no repeated errors connecting to MongoDB.
kubectl logs -n armonik deploy/metrics-exporter

# Shows HPA target metrics per partition — a healthy HPA shows numeric
# current/target values once tasks are queued.
kubectl describe hpa -n armonik
```

KEDA HPAs showing `<unknown>` on every partition is expected when all partitions are idle (scaled to zero). The problem is if they still show `<unknown>` after tasks are submitted.

---

## Queue back-ends

The active queue adapter is declared in `core-configmap`:

```bash
# Prints the path of the loaded queue adapter assembly — expect a path
# containing "Amqp", "SQS", or "PubSub" depending on your configured backend.
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
# Tails the broker logs — expect "Apache ActiveMQ ... started" (or
# RabbitMQ's equivalent banner) with no repeated TLS/auth errors.
kubectl logs -n armonik deploy/activemq

# Confirms the three required secrets exist — expect all three names
# echoed back; a "NotFound" error means that secret is missing.
kubectl get secret activemq activemq-server-certificates activemq-user-credentials -n armonik

# Dumps the Amqp__* configuration keys — verify Amqp__Host, Amqp__Scheme,
# and Amqp__CaPath match your broker's actual settings.
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
# Dumps the SQS__* configuration keys — verify SQS__PartitionId and the
# AWS region match the queues you pre-created.
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
# Dumps the PubSub__* configuration keys — verify PubSub__ProjectId and
# the topic/subscription names match what exists in the GCP project.
kubectl get configmap core-configmap -n armonik -o yaml | grep -i pubsub

# Checks for the Workload Identity annotation on the service account —
# expect a line like iam.gke.io/gcp-service-account: <sa>@<project>.iam.gserviceaccount.com.
# No output means the binding is missing.
kubectl describe serviceaccount -n armonik <control-plane-sa> | grep -i workload
```

---

## Object storage back-ends

The active adapter is declared in `core-configmap`:

```bash
# Prints the path of the loaded object storage adapter assembly — expect
# a path containing "Redis", "S3", "Gcs", or "FS" (HostPath) depending on
# your configured backend.
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
# Tails the Redis container logs — expect "Ready to accept connections"
# with no repeated TLS handshake errors.
kubectl logs -n armonik deploy/redis

# Dumps the Redis__* configuration keys — verify Redis__SslHost matches
# the certificate CN and Redis__CaPath points to a mounted CA file.
kubectl get configmap core-configmap -n armonik -o yaml | grep Redis__
```

### Amazon S3

| Symptom | Where to look |
|---|---|
| Cannot write payloads | IAM permissions — needs `s3:PutObject`, `s3:GetObject`, `s3:DeleteObject` on the target bucket |
| Bucket not found | Bucket must be pre-created and match `S3__BucketName` |
| Auth errors | If using a Kubernetes secret instead of IRSA, verify `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` |

```bash
# Dumps the S3__* configuration keys — verify S3__BucketName matches an
# existing bucket and S3__EndpointUrl/region are correct for your provider.
kubectl get configmap core-configmap -n armonik -o yaml | grep -i s3
```

### Google Cloud Storage (GCS)

ArmoniK uses a **native GCS adapter** (`ArmoniK.Core.Adapters.Gcs`) backed by the `Google.Cloud.Storage.V1` client library. It does **not** use GCS's S3-compatible endpoint — HMAC keys and S3-style env vars do not apply here.

Configuration lives under the `Gcs` section (double-underscore convention: `Gcs__BucketName`, `Gcs__ProjectId`, `Gcs__CredentialsFilePath`, etc.). For the full list of `Gcs__*` options and their defaults, see the [environment variables reference](https://armonikcore.readthedocs.io/en/latest/content/envars/index.html).

| Symptom | Cause |
|---|---|
| `InitObjectStorage` fails immediately | `Gcs__BucketName` is empty or the bucket does not exist — `Init()` calls `GetBucketAsync` and fails with 404 |
| `403 Forbidden` during init or at runtime | The service account is missing IAM permissions on the bucket: requires `storage.objects.create`, `storage.objects.get`, `storage.objects.delete` (and `storage.buckets.get` for the health check) |
| Auth error at startup, pod crashes before init | `Gcs__CredentialsFilePath` points to a non-existent or malformed JSON file — the client fails to build before any GCS call is made |
| Silent ADC fallback → `403` | `Gcs__CredentialsFilePath` is empty and no ADC is available (no `GOOGLE_APPLICATION_CREDENTIALS` env var, no Workload Identity on the pod's service account, no metadata server reachable) |
| Pod hangs → Terraform 2-minute timeout | Egress to `storage.googleapis.com:443` is blocked by a `NetworkPolicy` or node firewall rule |

```bash
# Dumps the Gcs__* configuration keys — verify Gcs__ProjectId and
# Gcs__BucketName are set and the bucket exists.
kubectl get configmap core-configmap -n armonik -o yaml | grep Gcs__

# Check the credentials file is mounted at the path matching
# Gcs__CredentialsFilePath — expect a volume mount entry with that path
# in the listed Mounts.
kubectl describe pod -n armonik <control-plane-pod> | grep -A5 "Mounts:"

# For Workload Identity: verify the SA annotation — expect a line like
# iam.gke.io/gcp-service-account: <sa>@<project>.iam.gserviceaccount.com.
# No output means the binding is missing.
kubectl describe serviceaccount -n armonik <pod-sa> | grep iam.gke.io
```

### Local / HostPath storage

| Symptom | Where to look |
|---|---|
| Pods fail to start | HostPath directory must exist on the node before the pod is scheduled |
| Data not accessible across nodes | HostPath is node-local — use NFS if pods span multiple nodes |
| Permission denied | Directory must be readable/writable by the container's UID |
| Worker libraries not found | The same HostPath mounts worker `.so`/DLL files — verify the data directory is populated |

```bash
# Dumps the shared-storage secret — expect a host_path key with a
# base64-encoded filesystem path as its value.
kubectl get secret shared-storage -n armonik -o yaml

# Decodes that path and lists its contents — expect worker library
# files (.so/.dll) and any shared task data to be present and readable.
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
# Tails the metrics-exporter logs — expect periodic messages with no
# repeated MongoDB connection errors.
kubectl logs -n armonik deploy/metrics-exporter

# Confirms the metrics-exporter secret exists — a "NotFound" error
# explains why the pod is stuck in ContainerCreating.
kubectl get secret metrics-exporter -n armonik
```

---

## Ingress / nginx

| Symptom | Where to look |
|---|---|
| Pod not starting | ConfigMaps `nginx-conf` and `nginx-static` must exist |
| LoadBalancer IP not assigned | Check the underlying load balancer controller |
| gRPC connection refused from outside | Control-plane service on port `5001` must be healthy |

```bash
# Tails the nginx ingress logs — expect access log lines for incoming
# requests; configuration errors on startup show as "emerg"/"alert" entries.
kubectl logs -n armonik deploy/nginx

# Shows the nginx Service details — for LoadBalancer type, expect an
# external IP under "LoadBalancer Ingress"; <pending> means no external
# IP has been assigned yet.
kubectl describe svc nginx -n armonik
```

---

## Monitoring stack

### Log aggregation

On localhost and on-premise deployments, ArmoniK ships with **Seq** as the default structured-log backend. Cloud deployments may instead route logs to the provider's native service (e.g. CloudWatch Logs on AWS, Cloud Logging on GCP) — adapt the commands below accordingly.

```bash
# Tails the Seq container logs — expect "Seq listening on ..." with no
# repeated startup errors.
kubectl logs -n armonik deploy/seq

# Shows the log retention CronJob's schedule and last run status —
# expect a recent "last schedule time" with no failed runs.
kubectl describe cronjob seq-retention-job -n armonik   # manages log retention

# Forwards the Seq web console to localhost:8080 — open
# http://localhost:8080 in a browser to view ingested logs.
kubectl port-forward -n armonik svc/seq-web-console 8080:8080
```

| Symptom | Where to look |
|---|---|
| Pod not starting | Secret `seq` must exist |
| No logs ingested | Fluent Bit must be running and pointing to `seq:5341` |

### Prometheus

```bash
# Tails the Prometheus container logs — expect "Server is ready to
# receive web requests" with no repeated scrape errors.
kubectl logs -n armonik deploy/prometheus

# Forwards the Prometheus UI to localhost:9090.
kubectl port-forward -n armonik svc/prometheus 9090:9090
# Then open http://localhost:9090/targets to check scrape status — all
# ArmoniK targets should show State "UP".
```

| Symptom | Where to look |
|---|---|
| Missing ArmoniK task metrics | `metrics-exporter` on port `9419` must be up |

### Grafana

```bash
# Tails the Grafana container logs — expect "HTTP Server Listen" with no
# repeated datasource connection errors.
kubectl logs -n armonik deploy/grafana
```

| Symptom | Where to look |
|---|---|
| No data in dashboards | Prometheus service must be reachable at `prometheus:9090` |
| Login fails | Secret `grafana` (admin credentials) must exist |

### Fluent Bit

Fluent Bit runs as a DaemonSet (one pod per node).

```bash
# Tails logs from all Fluent Bit pods — expect periodic "flush" success
# messages with no repeated connection errors to seq:5341.
kubectl logs -n armonik -l app=fluent-bit

# Shows the DaemonSet rollout status — DESIRED, CURRENT, and READY should
# all equal the number of nodes in the cluster.
kubectl describe daemonset fluent-bit -n armonik
```

| Symptom | Where to look |
|---|---|
| Logs not appearing in Seq | Check Fluent Bit logs for connection errors to `seq:5341` |
| Node-level permission error | Fluent Bit needs read access to host log directories (`/var/log`, `/var/lib/docker/containers`) |

---

## Force-deleting a stuck pod

Before force-deleting, check the pod's `terminationGracePeriodSeconds`:

```bash
kubectl get pod -n armonik <pod-name> -o jsonpath='{.spec.terminationGracePeriodSeconds}'
```

A pod can legitimately stay in `Terminating` for as long as this value (some components, such as MongoDB, are configured with a large grace period to allow a clean shutdown). Only proceed with force deletion if the pod remains `Terminating` well past this period.

If `kubectl delete pod` leaves a pod in `Terminating` for more than a few minutes:

```bash
# Forcibly removes the pod from the API server without waiting for the
# kubelet to confirm termination — the pod disappears immediately.
kubectl delete pod -n armonik --force <pod-name>

# Confirm it is gone — expect an empty list (no resources found). If the
# pod is recreated by its controller, it should re-enter Running shortly after.
kubectl get pod -n armonik --field-selector metadata.name=<pod-name>
```

Use this only as a last resort — force deletion skips graceful shutdown and can leave orphaned resources.

---

## Image pull failures

```bash
# Shows the pod's recent events — an ImagePullBackOff/ErrImagePull
# reason with a message naming the image and tag confirms a pull failure.
kubectl describe pod -n armonik <pod-name> | grep -A5 "Events:"
```

All ArmoniK images are published to Docker Hub under `dockerhubaneo/*`. Verify the exact tag you are deploying exists on Docker Hub. If you are behind a corporate proxy or air-gapped network, ensure the registry mirror is configured correctly.

---

## Finding the deployed URLs

After a successful deployment, the service URLs are printed to the console and stored in the Terraform output file:

```bash
# Admin GUI URL
jq -r '.armonik.admin_app_url' <path_to_armonik_repository>/infrastructure<deployment_type>/generated/armonik-output.json

# Seq URL (localhost deployments only)
jq -r '.armonik.seq_web_url' <path_to_armonik_repository>/infrastructure<deployment_type>/generated/armonik-output.json
```

Where the placeholder `<deployment_type>` is either localhost, aws or gcp according to your case.
Default ports: Admin GUI on `:5000`, Seq on `:8080`.
