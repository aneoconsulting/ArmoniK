# Autoscaling bench

How the compute plane follows the load: tasks (KEDA's input), pods (HPA), cores and nodes (Karpenter). It runs
clients as Jobs in the cluster, from a cold start (0 pod, 0 workers node), then exports the Prometheus series of the
run. Uses the partitions of `terraform/k8s/terraform.tfvars` and the `autoscaling-monitoring` release (Grafana
dashboard "ArmoniK autoscaling").

## Commands

```sh
uv run bench.py list                              # the scenarios, their partition and work

# A/B of the autoscaling target: B = queued / 2, P = the flow model in PromQL
uv run bench.py suite                             # the whole suite once, each scenario in B then P (~2 h 15)
uv run bench.py suite --configs p                 # P only (~1 h 10)
uv run bench.py suite --repeat 2                  # twice, the order rotated the second time
uv run bench.py suite s14-waves-200ms s11-burst-200ms   # some scenarios only
uv run bench.py run s12-steady-200ms --config p   # one run
uv run bench.py suite s16-long                    # long tasks (~25 min a run)

uv run bench.py report runs/suite-<date>          # the configs side by side: report.md, report.csv, one overlay plot per scenario
uv run bench.py report runs/suite-*               # several suites in one report (in runs/report-<date>/)

uv run bench.py run s1-burst-cold                 # a scenario on the bench partition (long tasks)
uv run bench.py compare runs/*                    # one KPI line per run
uv run bench.py export runs/<dir>                 # export and plot again, e.g. after a change of the queries
uv run bench.py plot runs/<dir>
```

Each run waits for 0 pod and 0 workers node, starts the clients, waits for them and for the scale-down to 0, then
exports. It prints the Grafana link of the run: live at the start, on the exact time range at the end. A run takes
7 to 15 min, mostly the scale-down.

## Partitions

The A/B scenarios run on twin partitions: same worker, same fast HPA, only the KEDA metric differs. One workload per
pair, so that each partition measures its own task duration.

| Partitions | Worker | Used by |
|---|---|---|
| `short200b` / `short200p` | bench, tasks of 200 ms | s11, s12, s14 |
| `short1sb` / `short1sp` | bench, tasks of 1 s | s8, s15 |
| `htcmockb` / `htcmockp` | HtcMock, subtasks | s9, s10, s7 |
| `longb` / `longp` | bench, tasks of 5 min | s16 |
| `bench` | bench, B only | s1 to s5, s13 |

`b` scales on `queued / 2`, `p` on `armonik:scaler_target` (PromQL, below). The PromQL target is computed for every
partition: on a B partition the dashboard shows what P would have asked for.

## Scenarios

The suite (short tasks):

| Scenario | Load | What it shows |
|---|---|---|
| `s12-steady-200ms` | 20 tasks/s of 200 ms for 5 min | a steady flow: B grows with the prefetched tasks, P follows Little's law (~9 pods) |
| `s14-waves-200ms` | 10 tasks/s of 200 ms for 8 min, bursts of 3000 at 2 and 5 min | a service with peaks: P must go up and down with the load |
| `s11-burst-200ms` | 6000 tasks of 200 ms at once | a batch from 0: both hit the cold start, the gain is smaller |
| `s8-burst-short` | 2000 tasks of 1 s at once | the same with longer tasks: P may be slower (60 s catch-up time) |
| `s15-waves-1s` | 3 tasks/s of 1 s for 8 min, bursts of 1000 at 2 and 5 min | s14 with 1 s tasks |
| `s9-htcmock-200ms` | HtcMock, 3000 tasks of ~200 ms on 3 levels | subtasks, and a long root task among short ones |

Not in the suite: `s16-long` (2 batches of 40 tasks of 5 min: one pod per task, kept to the end of the batch),
`s10-htcmock-1s` (shares `htcmock{b,p}` with s9), `s7-htcmock`, and on `bench` the long-task
scenarios `s1-burst-cold` (1000 × 10 s), `s2-burst-warm` (two s1 bursts in the cooldown), `s3-steady` (5/s × 10 s),
`s4-mixed` (1 s to 2 min together), `s5-waves-2min` (3 waves of 200 × 10 s), `s13-burst-500ms` (4000 × 500 ms).

## Results

`runs/` is git-ignored. A run writes `runs/<date>-<scenario>[-b|-p]/` (in `runs/suite-<date>/` for a suite):
`run.json`, `autoscaling.json` (ScaledObject, HPA and NodePool as they were), `metrics.csv` (5 s steps), `plot.png`,
`kpis.json`, `clients.log`.

`report.md` starts with a summary line per scenario, then one table per scenario (mean of the runs, min-max when
there are several, change of P against B) and the overlay plot of a typical run (median idle pod·s): pods paid and
busy, then the waiting tasks, B in orange and P in green.

| KPI | Meaning |
|---|---|
| `paid_core_h` | core·h of the workers nodes over the run: the cost (nodes are paid, not pods) |
| `idle_pod_s` | ready pod·s without a task: the waste the target acts on |
| `ready_pod_s`, `mean_ready_pods` | pod·s paid over the run, ready pods averaged from the first to the last task |
| `drain_s` | first task to 5 tasks left: the few tasks stuck in SQS for minutes do not count |
| `makespan_s` / `ideal_makespan_s` | first to last task in the system / work divided by `maxReplicaCount` |
| `mean_queue_wait_s` | mean time a task waits in Submitted (Little: queue integral / tasks) |
| `first_ready_s`, `first_node_s` | first task to first ready pod / first workers node: the cold start |
| `peak_desired`, `peak_ready`, `peak_processing` | highest HPA target, ready pods, tasks running at once |
| `efficiency` | work core·s / workers core·s paid |
| `tail_to_0_pod_s`, `tail_to_0_node_s` | last task to 0 pod / 0 workers node |

Compare `paid_core_h` rather than node counts: P scales by steps, so Karpenter starts more, smaller nodes.

## PromQL target (config P)

A flow model (Little's law) as Prometheus recording rules, from Core's own series: the exporter's counts
(submitted, dispatched, processing) and the polling agents' metrics (`TaskHandler_*_milliseconds`, `TaskRunningTime`).
`charts/autoscaling-monitoring/rules/autoscaling.rules.yaml`, loaded as a PrometheusRule by the `autoscaling-monitoring`
release; the partitions with `promql = true` scale on `armonik:scaler_target{partition="<p>"}` (`terraform/k8s/releases.tf`).

```
target = ceil( max(F, R) + W ), at least 1 while a task is processing
F = min(arrivals, completions) * mu / 0.9         arrivals = completions + growth of the tasks in the system (30 s)
R = processing * min(mu / 2, 60) / 60             long tasks keep one pod each
W = waiting * min(mu / (60 * 0.9), 1)             the queue in 60 s, at most one pod per task
mu = pre + execute + post processing per task; before the first completions, the median measure of the last hour or 1 s,
     raised to the median age of the running tasks
```

Unit tests (synthetic series: steady flow, drain, long tasks, cold start, running ages, exporter missing):

```sh
cd ../charts/autoscaling-monitoring/rules
podman run --rm -v "$PWD:/r:Z" -w /r --entrypoint promtool docker.io/prom/prometheus:v3.5.1 test rules autoscaling.rules.test.yaml
```

Prometheus is in the scaling path: the trigger has `ignoreNullValues: "false"`, so an empty answer (rules not loaded yet,
exporter or Prometheus down) makes KEDA apply the fallback (keep the current pods) instead of scaling to 0. During the
first `terraform apply` with P partitions, they run on that fallback until the `autoscaling-monitoring` release is updated.
