# Testing & CI

This page describes the automated checks that run on every contribution to the main ArmoniK repository and explains how to run the same tests locally before pushing.

---

## CI pipeline overview

| Workflow | Trigger | What it checks |
|---|---|---|
| **Deploy & Test (localhost)** | Every push to any branch | Full integration suite: deploy a fresh local K3s stack and run end-to-end tests |
| **Formatting** | Push to `main`, all PRs | Terraform file formatting (`terraform fmt`) |
| **Lint PR** | PR opened / edited / synchronised | PR title follows [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/) |
| **Benchmark** | Push to `main`, releases, manual | Performance benchmark suite (localhost + optionally AWS) |
| **Deploy & Test AWS** | Manual | Full integration suite on a real AWS deployment |

---

## Integration tests (Deploy & Test)

Each integration test job follows the same pattern:

1. Spin up a fresh K3s cluster on the CI runner
2. Deploy ArmoniK via the `all-in-one` Terraform configuration
3. Run the test client against the live deployment
4. Collect logs and upload them to S3 (for post-mortem if a job fails)
5. Destroy the deployment

The jobs run in parallel, each with its own isolated deployment. A job timeout of **40 minutes** applies to the heavier test suites.

### Jobs

#### AdminGUI

Verifies the Admin GUI and Admin API containers are reachable after deployment:

```bash
curl -fsSL "${ADMIN_APP_URL}" -o /dev/null
curl -fsSL "${ADMIN_API_URL}" -o /dev/null
```

#### Core Stream

The Stream worker is a minimal test worker that submits tasks, streams results back, and validates they arrive correctly. It exercises the full task submission → execution → result retrieval path end-to-end with no application-level complexity.

Submits tasks using the Stream test worker:

```bash
docker run --rm \
  -e GrpcClient__Endpoint="${CONTROL_PLANE_URL}" \
  -e Partition="stream" \
  dockerhubaneo/armonik_core_stream_test_client:<core-version>
```

#### HTC Mock

HTC Mock is a synthetic workload generator that simulates realistic task graphs. It creates a configurable number of tasks arranged in a dependency tree of a given depth, with tunable compute time, payload size, and memory usage. It is the primary correctness test for ArmoniK's dependency resolution and scheduling logic.

Runs four scenarios at different DAG depths:

| Scenario | Tasks | Levels | Mode |
|---|---|---|---|
| Default | 2 000 | 5 | Normal compute |
| 1 level | 1 000 | 1 | Fast / low-memory |
| 5 levels | 1 000 | 5 | Fast / low-memory |
| 10 levels | 1 000 | 10 | Fast / low-memory |

#### Bench

The Bench client submits a configurable batch of tasks with controlled duration, payload size, and result size, then waits for completion and reports execution statistics. It is used to catch regressions in throughput and data-path performance rather than correctness.

Runs four scenarios to cover distinct performance dimensions:

| Scenario | Tasks | Duration | Payload | Result |
|---|---|---|---|---|
| Many tasks | 200 | 100 ms | — | — |
| Long tasks | 2 | 10 s | — | — |
| Large payloads | 10 | 10 ms | 10 MB | 1 KB |
| Large results | 10 | 10 ms | 1 KB | 10 MB |

#### MCP Auth

The **ArmoniK Load Balancer** (also referred to as the Meta Control Plane, or MCP) is a component that exposes a single gRPC endpoint in front of multiple ArmoniK clusters. When a session is created, the Load Balancer selects a cluster using round-robin scheduling and routes all tasks of that session to the selected cluster. Clients need no modification — they connect to the Load Balancer exactly as they would connect to a single Control Plane.

This test job validates the authentication and authorisation layer in a topology where the Load Balancer sits behind an nginx ingress with mTLS enabled. The setup is:

```
Client (with client cert)
  └─> nginx (TLS termination, mTLS, forwards identity headers)
        └─> ArmoniK Load Balancer (connects to ArmoniK with its own mTLS client cert)
              └─> ArmoniK Control Plane (requires authentication + authorisation)
```

The job:
1. Deploys ArmoniK with TLS, mTLS, and authentication enabled
2. Generates a custom CA and client certificates (`tools/ci/python/generate_auth_conf.py`)
3. Starts nginx + the Load Balancer via Docker Compose
4. Runs a `pytest` suite that verifies correct behaviour for authenticated, unauthenticated, and unauthorised clients:

```bash
pytest -v tools/ci/python/mcp_tests.py
```

---

## Running integration tests locally

You can run any of the CI test commands against your local deployment. First ensure your stack is running and export the control plane URL:

```bash
export CONTROL_PLANE_URL=$(cat infrastructure/quick-deploy/localhost/all-in-one/generated/armonik-output.json \
  | jq -r '.armonik.control_plane_url')
```

Then run any client — for example, HTC Mock with 1 000 tasks at 5 dependency levels:

```bash
CORE_TAG=$(jq -r '.armonik_versions.core' versions.tfvars.json)

docker run --rm \
  -e GrpcClient__Endpoint="${CONTROL_PLANE_URL}" \
  -e HtcMock__NTasks=1000 \
  -e HtcMock__SubTasksLevels=5 \
  -e HtcMock__EnableFastCompute=true \
  -e HtcMock__EnableSmallOutput=true \
  -e HtcMock__EnableUseLowMem=true \
  -e HtcMock__Partition="htcmock" \
  dockerhubaneo/armonik_core_htcmock_test_client:${CORE_TAG}
```

Or the Bench client:

```bash
docker run --rm \
  -e GrpcClient__Endpoint="${CONTROL_PLANE_URL}" \
  -e BenchOptions__NTasks=200 \
  -e BenchOptions__TaskDurationMs=100 \
  -e BenchOptions__Partition="bench" \
  dockerhubaneo/armonik_core_bench_test_client:${CORE_TAG}
```

---

## Static checks

### Terraform formatting

All `.tf` files must be formatted with the canonical Terraform style. Check locally before pushing:

```bash
terraform fmt -check -recursive -diff
```

To auto-fix formatting issues:

```bash
terraform fmt -recursive
```

This check runs on every PR and on every push to `main`.

### PR title convention

PR titles must follow the [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/) specification. The CI will post an error comment if the title does not match.

Accepted prefixes: `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`, `revert`.

Examples:
- `feat: add GCS object storage adapter`
- `fix: correct HPA cooldown period default`
- `docs: add troubleshooting section for PubSub`

---

## Skipping CI

Add `[skip ci]` anywhere in the commit message to skip the integration tests for that push. Use this for documentation-only changes or work-in-progress commits where running a full deployment is unnecessary.

```bash
git commit -m "docs: update README [skip ci]"
```

---

## Benchmark workflow

The benchmark workflow runs on every push to `main` (localhost only) and on every release (localhost + AWS). It can also be triggered manually from the GitHub Actions UI with configurable parameters:

- **localhost** — 3 000 tasks, benchmark results stored as workflow artifacts
- **AWS** — 1 200 000 tasks, full-scale throughput measurement (releases only)

Results are stored per run and compared against previous runs to detect regressions. See [Benchmarking & Performance](../benchmarking/test-plan.md) for result interpretation.

---

## Log collection

On CI, each job collects logs from all `armonik_*` pods and uploads them as a compressed archive to S3 at:

```
s3://<log-bucket>/armonik-pipeline/<run-number>/<run-attempt>/<job-name>.tar.gz
```

Each archive contains:
- `infra/generated/armonik-output.json` — Terraform outputs (service URLs, config)
- `infra/tfstates/armonik-terraform.tfstate` — Terraform state snapshot
- `app/armonik_*/` — Pod logs from all ArmoniK components

```{note}
The S3 bucket storing CI logs is only accessible to the ArmoniK development team. If you are an external contributor and need logs from a failed CI run, ask a team member to retrieve and share the relevant archive.
```
