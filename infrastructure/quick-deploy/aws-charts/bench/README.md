# Autoscaling bench

How the compute plane follows the load: tasks (KEDA's input), pods (HPA), cores and nodes (Karpenter). Uses the
`bench` and `htcmock` partitions of `terraform/k8s/terraform.tfvars` and the `autoscaling-monitoring` release
(Karpenter ServiceMonitor, Grafana dashboard "ArmoniK autoscaling").

```sh
uv run bench.py list                  # the scenarios
uv run bench.py run s1-burst-cold     # clients as Jobs, waits for the scale-down, then exports and plots
uv run bench.py compare runs/*        # one KPI line per run
```

Each run writes `runs/<date>-<scenario>/` (git-ignored): `run.json`, `autoscaling.json` (ScaledObject, HPA and
NodePool as they were), `metrics.csv` (5 s steps), `plot.png`, `kpis.json`.

| KPI | Meaning |
|---|---|
| `makespan_s` / `ideal_makespan_s` | first to last task in the system / work divided by `maxReplicaCount` |
| `first_ready_s`, `first_node_s` | first task to first ready pod / first workers node |
| `peak_desired`, `peak_ready`, `peak_processing` | highest HPA target, ready pods, tasks running at once |
| `mean_waiting_tasks` | tasks in Submitted, averaged over the makespan |
| `efficiency` | work core·s / workers nodes core·s paid over the run |
| `idle_pod_s` | ready pod·s without a task |
| `tail_to_0_pod_s`, `tail_to_0_node_s` | last task to 0 pod / 0 workers node |
