# /// script
# requires-python = ">=3.11"
# dependencies = ["matplotlib>=3.8"]
#
# # A uv-managed Python: the numpy wheels need the system libstdc++, which a Nix Python does not see
# [tool.uv]
# python-preference = "only-managed"
# ///
"""Autoscaling bench of the compute plane: runs a scenario as client Jobs in the cluster, then exports the
Prometheus series of the run (tasks, pods, cores, nodes) to CSV, plots them and computes the KPIs.

    uv run autoscaling.py list
    uv run autoscaling.py run s1-burst-cold      # run + export + plot + kpis, in runs/<date>-<scenario>/
    uv run autoscaling.py export runs/<dir>      # again, e.g. after a change of the queries
    uv run autoscaling.py plot runs/<dir>
    uv run autoscaling.py compare runs/*         # one KPI line per run
    uv run autoscaling.py suite --repeat 2       # the laws against each other: each SUITE scenario in q, d and m, rotated
    uv run autoscaling.py suite --configs q m    # only some laws
    uv run autoscaling.py report runs/<suite>    # the laws side by side: report.md (tables), one overlay plot per scenario

kubectl uses $KUBECONFIG, or ../generated/kubeconfig when it is not set. The laws: ../autoscaling/README.md.
"""

from __future__ import annotations

import argparse
import contextlib
import csv
import json
import os
import pathlib
import socket
import subprocess
import sys
import time
import urllib.parse
import urllib.request
from dataclasses import asdict, dataclass, field
from datetime import datetime, timezone

HERE = pathlib.Path(__file__).resolve().parent
RUNS = HERE / "runs"
NS = "armonik"
PROMETHEUS = ("operators", "svc/kps-prometheus", 9090)
# Through the ingress: nginx spreads each gRPC request over the control plane pods
ENDPOINT = "http://armonik-ingress.armonik.svc:5001"
WORKERS = "cloud.google.com/compute-class=workers"  # nodes of the partitions (compute-classes.tf)
STEP = 5  # seconds between two exported points

os.environ.setdefault("KUBECONFIG", str(HERE.parent / "generated" / "kubeconfig"))


# ---- Scenarios ---------------------------------------------------------------------------------------------


@dataclass
class Client:
    """One client Job, started `at` seconds after the beginning of the run."""

    at: int
    ntasks: int
    duration_ms: int = 0  # Bench: duration of each task
    kind: str = "bench"  # bench or htcmock
    htcmock_total: str = ""  # HtcMock: TotalCalculationTime, split over the tasks
    htcmock_levels: int = 3

    @property
    def work_s(self) -> float:
        """CPU seconds of work the client submits (1 task = 1 core for its duration)."""
        if self.kind == "htcmock":
            h, m, s = (float(x) for x in self.htcmock_total.split(":"))
            return h * 3600 + m * 60 + s
        return self.ntasks * self.duration_ms / 1000


@dataclass
class Scenario:
    name: str
    # ab: a base name, the partition is <base><config> (CONFIGS), see terraform.tfvars
    partition: str
    description: str
    clients: list[Client]
    # True: measure the natural scale-down (cooldown, consolidation) up to 0 pod / 0 node, ~9 min.
    # False: stop 30 s after the clients, then reset() forces the partition and the workers pool to 0, ~2 min.
    measure_tail: bool = False
    ab: bool = False

    def partition_for(self, config: str | None) -> str:
        if not self.ab:
            return self.partition
        if config not in CONFIGS:
            sys.exit(f"{self.name} runs on twin partitions: --config {' or '.join(CONFIGS)}")
        return self.partition + config


# The law the twin partition scales on (autoscaling = { law = ... } in terraform.tfvars), all with the fast HPA:
# q: the chart's trigger, queued / 2; d: waiting and running raced; m: the flow model.
CONFIGS = {"q": "queue", "d": "dual", "m": "model"}


def steady(rate_per_s: float, duration_ms: int, minutes: int, every_s: int = 10) -> list[Client]:
    per_job = round(rate_per_s * every_s)
    return [Client(at=t, ntasks=per_job, duration_ms=duration_ms) for t in range(0, minutes * 60, every_s)]


def waves(rate_per_s: float, duration_ms: int, minutes: int, bursts: list[tuple[int, int]]) -> list[Client]:
    """A steady flow with bursts (at s, tasks) on top: a service with peaks of load."""
    return steady(rate_per_s, duration_ms, minutes) + [Client(at, n, duration_ms) for at, n in bursts]


SCENARIOS = {
    s.name: s
    for s in [
        Scenario("s1-burst-cold", "bench", "1000 tasks of 10 s at once, from 0 pod and 0 node",
                 [Client(0, 1000, 10_000)], measure_tail=True),
        Scenario("s2-burst-warm", "bench", "two s1 bursts 270 s apart: the second finds the pods still up (cooldown)",
                 [Client(0, 1000, 10_000), Client(270, 1000, 10_000)]),
        Scenario("s3-steady", "bench", "5 tasks/s of 10 s for 5 min (50 tasks in flight at equilibrium)",
                 steady(5, 10_000, 5)),
        Scenario("s4-mixed", "bench", "durations from 1 s to 2 min submitted together: the tail and scale-down",
                 [Client(0, 400, 1_000), Client(0, 200, 10_000), Client(0, 60, 60_000), Client(0, 20, 120_000)],
                 measure_tail=True),
        Scenario("s5-waves-2min", "bench", "3 waves of 200 tasks of 10 s, every 2 min (inside the cooldown)",
                 [Client(t, 200, 10_000) for t in range(0, 360, 120)]),
        Scenario("s13-burst-500ms", "bench", "4000 tasks of 500 ms at once, from 0 pod: ~0.8 s per task with the Core overhead, ~60 pods",
                 [Client(0, 4000, 500)], measure_tail=True),
        # The laws on short tasks (suite): twin partitions short200{q,d,m}, short1s{q,d,m}, htcmock{q,d,m}
        Scenario("s12-steady-200ms", "short200", "20 tasks/s of 200 ms for 5 min: ~9 pods busy at equilibrium (Little)",
                 steady(20, 200, 5), measure_tail=True, ab=True),
        Scenario("s14-waves-200ms", "short200", "10 tasks/s of 200 ms for 8 min, with bursts of 3000 at 2 and 5 min",
                 waves(10, 200, 8, [(120, 3000), (300, 3000)]), measure_tail=True, ab=True),
        Scenario("s11-burst-200ms", "short200", "6000 tasks of 200 ms at once, from 0 pod: ~0.4 s per task with the Core overhead",
                 [Client(0, 6000, 200)], measure_tail=True, ab=True),
        Scenario("s8-burst-short", "short1s", "2000 tasks of 1 s at once, from 0 pod",
                 [Client(0, 2000, 1_000)], measure_tail=True, ab=True),
        Scenario("s15-waves-1s", "short1s", "3 tasks/s of 1 s for 8 min, with bursts of 1000 at 2 and 5 min",
                 waves(3, 1_000, 8, [(120, 1000), (300, 1000)]), measure_tail=True, ab=True),
        Scenario("s9-htcmock-200ms", "htcmock", "HtcMock: 3000 tasks of ~200 ms on 3 levels of subtasks (10 min of compute)",
                 [Client(0, 3000, kind="htcmock", htcmock_total="00:10:00", htcmock_levels=3)], measure_tail=True, ab=True),
        Scenario("s10-htcmock-1s", "htcmock", "HtcMock: 3000 tasks of ~1 s on 3 levels of subtasks (50 min of compute)",
                 [Client(0, 3000, kind="htcmock", htcmock_total="00:50:00", htcmock_levels=3)], measure_tail=True, ab=True),
        # Long tasks (not in the suite: ~25 min a run): 40 tasks of 5 min, fewer than the 100 pods. A waiting task needs
        # one pod (uncapped, W would ask 40 * 300 / 54 = 222), the running ones keep theirs at the end of the batch (R;
        # the queue law removes half of them), and before the first completion the task duration comes from the
        # running ages. The second batch finds the duration measured by the first one.
        Scenario("s16-long", "long", "2 batches of 40 tasks of 5 min, 7 min apart: one pod per task, kept to the end",
                 [Client(0, 40, 300_000), Client(420, 40, 300_000)], measure_tail=True, ab=True),
        Scenario("s7-htcmock", "htcmock", "HtcMock: 1000 tasks on 3 levels of subtasks, 30 min of compute in total",
                 [Client(0, 1000, kind="htcmock", htcmock_total="00:30:00", htcmock_levels=3)], ab=True),
    ]
}

# The suite: short tasks, one workload per partition (s10 would share htcmock{q,d,m} with s9: not in it)
SUITE = ["s12-steady-200ms", "s14-waves-200ms", "s11-burst-200ms", "s8-burst-short", "s15-waves-1s", "s9-htcmock-200ms"]


# ---- Kubernetes ----------------------------------------------------------------------------------------------


def kubectl(*args: str, stdin: str | None = None, check: bool = True) -> str:
    r = subprocess.run(["kubectl", *args], input=stdin, capture_output=True, text=True)
    if check and r.returncode != 0:
        sys.exit(f"kubectl {' '.join(args)}: {r.stderr.strip()}")
    return r.stdout


def kget(*args: str) -> dict:
    return json.loads(kubectl("get", *args, "-o", "json"))


def dockerhub_registry() -> tuple[str, str]:
    """(Docker Hub pull-through prefix, Core tag), read from the control plane image: no account id here."""
    image = kget("-n", NS, "deploy", "armonik-control-plane")["spec"]["template"]["spec"]["containers"][0]["image"]
    registry, _, rest = image.partition("/dockerhubaneo/")
    return registry, rest.split(":")[1]


def client_job(run_id: str, i: int, c: Client, partition: str, registry: str, core: str) -> dict:
    if c.kind == "htcmock":
        image = f"{registry}/dockerhubaneo/armonik_core_htcmock_test_client:{core}"
        env = {
            "HtcMock__NTasks": c.ntasks,
            "HtcMock__TotalCalculationTime": c.htcmock_total,
            "HtcMock__SubTasksLevels": c.htcmock_levels,
            "HtcMock__EnableFastCompute": "false",  # the workers really spend the calculation time
            "HtcMock__Partition": partition,
        }
    else:
        image = f"{registry}/dockerhubaneo/armonik_core_bench_test_client:{core}"
        env = {
            "BenchOptions__NTasks": c.ntasks,
            "BenchOptions__TaskDurationMs": c.duration_ms,
            "BenchOptions__Partition": partition,
            "BenchOptions__DegreeOfParallelism": 8,
            "BenchOptions__DownloadResults": "false",
            "BenchOptions__MaxDuration": "01:00:00",
        }
    env["GrpcClient__Endpoint"] = ENDPOINT
    labels = {"app.kubernetes.io/part-of": "autoscaling-bench", "bench.armonik.fr/run": run_id}
    return {
        "apiVersion": "batch/v1",
        "kind": "Job",
        "metadata": {"name": f"{run_id}-{i}", "namespace": NS, "labels": labels},
        "spec": {
            "backoffLimit": 0,
            "ttlSecondsAfterFinished": 3600,
            "template": {
                # On the default class: the cluster autoscaler must not evict a running client
                "metadata": {"labels": labels,
                             "annotations": {"cluster-autoscaler.kubernetes.io/safe-to-evict": "false"}},
                "spec": {
                    "restartPolicy": "Never",
                    "containers": [{
                        "name": "client",
                        "image": image,
                        "env": [{"name": k, "value": str(v)} for k, v in env.items()],
                        "resources": {"requests": {"cpu": "200m", "memory": "256Mi"}, "limits": {"memory": "512Mi"}},
                    }],
                },
            },
        },
    }


def partition_state(partition: str) -> tuple[int, int]:
    """(replicas of the partition's Deployment, nodes of the workers ComputeClass)."""
    dep = kget("-n", NS, "deploy", f"armonik-compute-plane-{partition}")
    nodes = kget("nodes", "-l", WORKERS)["items"]
    return dep["status"].get("replicas", 0), len(nodes)


def wait_until(predicate, what: str, timeout_s: int, every_s: int = 10) -> bool:
    start = time.time()
    while time.time() - start < timeout_s:
        if predicate():
            return True
        print(f"  waiting for {what} ({int(time.time() - start)} s)", flush=True)
        time.sleep(every_s)
    print(f"  timeout after {timeout_s} s waiting for {what}")
    return False


def jobs_done(run_id: str) -> tuple[int, int, int]:
    """(active or pending, succeeded, failed) Jobs of the run."""
    items = kget("-n", NS, "jobs", "-l", f"bench.armonik.fr/run={run_id}")["items"]
    ok = sum(1 for j in items if j["status"].get("succeeded"))
    ko = sum(1 for j in items if j["status"].get("failed"))
    return len(items) - ok - ko, ok, ko


# ---- Run ---------------------------------------------------------------------------------------------------


def run(name: str, config: str | None = None, runs: pathlib.Path = RUNS) -> pathlib.Path:
    sc = SCENARIOS[name]
    partition = sc.partition_for(config)
    registry, core = dockerhub_registry()
    run_id = "asb-" + datetime.now().strftime("%m%d-%H%M%S")
    out = runs / (f"{datetime.now():%Y%m%d-%H%M%S}-{sc.name}" + (f"-{config}" if sc.ab else ""))
    out.mkdir(parents=True)
    print(f"{sc.name} on {partition}: {sc.description}\n  run {run_id}, Core {core}, results in {out}")

    wait_until(lambda: partition_state(partition) == (0, 0), "0 pod and 0 workers node", 900, 15)

    # What the autoscaling was, to compare runs after a change
    snapshot = {
        "scaledobject": kget("-n", NS, "scaledobject", f"armonik-compute-plane-{partition}")["spec"],
        "hpa": kget("-n", NS, "hpa", f"keda-hpa-armonik-compute-plane-{partition}")["spec"],
        "computeclass": kget("computeclass", "workers")["spec"],
    }
    meta = {
        "scenario": asdict(sc),
        "partition": partition,
        "config": config_of(snapshot["scaledobject"]),
        "ntasks": sum(c.ntasks for c in sc.clients if c.kind == "bench") or None,
        "run_id": run_id,
        "core": core,
        "work_core_s": sum(c.work_s for c in sc.clients),
        "max_replicas": snapshot["scaledobject"].get("maxReplicaCount"),
        "starts": {},
    }

    t0 = time.time()
    meta["t0"] = t0
    print(f"  Grafana (live): {grafana_url(partition, t0 - 60, None)}", flush=True)
    pending = sorted(enumerate(sc.clients), key=lambda x: x[1].at)
    while pending:
        i, c = pending[0]
        delay = t0 + c.at - time.time()
        if delay > 0:
            time.sleep(min(delay, 10))
            continue
        kubectl("apply", "-f", "-", stdin=json.dumps(client_job(run_id, i, c, partition, registry, core)))
        meta["starts"][i] = time.time()
        print(f"  +{int(time.time() - t0):4d} s  client {i}: {c.ntasks} tasks", flush=True)
        pending.pop(0)

    wait_until(lambda: jobs_done(run_id)[0] == 0, "the clients to finish", 4 * 3600, 15)
    meta["t_clients_done"] = time.time()
    active, ok, ko = jobs_done(run_id)
    meta["jobs"] = {"succeeded": ok, "failed": ko}
    print(f"  clients done: {ok} succeeded, {ko} failed")
    # Client logs: retried tasks (a pod killed by a scale-down while running one) show up there
    with (out / "clients.log").open("w") as f:
        for i in meta["starts"]:
            f.write(f"===== client {i}\n" + kubectl("logs", "-n", NS, f"job/{run_id}-{i}", check=False))

    if sc.measure_tail:
        wait_until(lambda: partition_state(partition) == (0, 0), "the scale-down to 0", 900, 30)
    else:
        time.sleep(30)
    meta["t1"] = time.time()

    (out / "run.json").write_text(json.dumps(meta, indent=2, default=str))
    (out / "autoscaling.json").write_text(json.dumps(snapshot, indent=2))
    export(out)
    if not sc.measure_tail:
        reset(partition)
    print(f"  Grafana: {grafana_url(partition, t0 - 60, meta['t1'] + 30)}")
    return out


def config_of(scaledobject: dict) -> str:
    """q, d or m, from the trigger of the ScaledObject."""
    trigger = scaledobject["triggers"][0]
    if trigger["type"] != "prometheus":
        return "q"
    return next((cfg for cfg, law in CONFIGS.items() if f'law="{law}"' in trigger["metadata"]["query"]), "m")


def grafana_url(partition: str, start: float, end: float | None) -> str:
    """The autoscaling dashboard on the run, through the load balancer (port 5000, /grafana/)."""
    lb = kget("-n", NS, "svc", "armonik-ingress")["status"]["loadBalancer"]["ingress"][0]
    to = "now" if end is None else str(int(end * 1000))
    return (f"http://{lb.get('ip') or lb.get('hostname')}:5000/grafana/d/armonik-bench-autoscaling"
            f"?var-partition={partition}&from={int(start * 1000)}&to={to}")


def suite(repeat: int, names: list[str], configs: list[str]) -> pathlib.Path:
    """Each scenario in every config, the order rotated on each repeat (no config always runs first), in
    runs/suite-<date>/."""
    runs = RUNS / f"suite-{datetime.now():%Y%m%d-%H%M%S}"
    runs.mkdir(parents=True)
    plan = [(n, cfg) for r in range(repeat) for n in names for cfg in configs[r % len(configs):] + configs[:r % len(configs)]]
    print(f"suite: {len(plan)} runs, ~10 min each, in {runs}")
    for k, (n, cfg) in enumerate(plan, 1):
        print(f"\n===== {k}/{len(plan)}  {n}  config {cfg} ({CONFIGS[cfg]})", flush=True)
        run(n, cfg, runs)
    report(sorted(d for d in runs.iterdir() if d.is_dir()), runs)
    return runs


def reset(partition: str) -> None:
    """Back to 0 pod without waiting for the cooldown. GKE removes the empty nodes itself, a minute later
    (consolidationDelayMinutes of the workers ComputeClass): the next run waits for them."""
    so = f"scaledobject/armonik-compute-plane-{partition}"
    kubectl("annotate", "-n", NS, so, "autoscaling.keda.sh/paused-replicas=0", "--overwrite")
    wait_until(lambda: partition_state(partition)[0] == 0, "the partition paused at 0", 300, 5)
    kubectl("annotate", "-n", NS, so, "autoscaling.keda.sh/paused-replicas-")
    print("  reset: partition at 0")


# ---- Export ------------------------------------------------------------------------------------------------


def queries(p: str) -> dict[str, str]:
    pod = f'namespace="{NS}",pod=~"armonik-compute-plane-{p}-[a-z0-9]+-[a-z0-9]+"'
    workers = 'max by (node) (kube_node_labels{label_cloud_google_com_compute_class="workers"})'
    spot = 'max by (node) (kube_node_labels{label_cloud_google_com_compute_class="workers",label_cloud_google_com_gke_spot="true"})'
    cap = 'kube_node_status_allocatable{resource="cpu"} * on (node) group_left () '
    sel = f'partition="{p}"'
    return {
        # Tasks
        "tasks_submitted": f"sum(armonik_{p}_tasks_submitted)",
        "tasks_dispatched": f"sum(armonik_{p}_tasks_dispatched)",
        "tasks_processing": f"sum(armonik_{p}_tasks_processing)",
        "keda_input": f'max(keda_scaler_metrics_value{{scaledObject="armonik-compute-plane-{p}"}})',
        # The three laws (autoscaling/rules.yaml), computed for every partition, and the terms of the model
        "target_queue": f'max(armonik:scaler_target{{{sel},law="queue"}})',
        "target_dual": f'max(armonik:scaler_target{{{sel},law="dual"}})',
        "target_model": f'max(armonik:scaler_target{{{sel},law="model"}})',
        "model_task_duration": f"max(armonik:task_duration_seconds{{{sel}}})",
        "model_flow_workers": f"max(armonik:scaler_flow_workers{{{sel}}})",
        "model_running_workers": f"max(armonik:scaler_running_workers{{{sel}}})",
        "model_waiting_workers": f"max(armonik:scaler_waiting_workers{{{sel}}})",
        "model_waiting_workers_predicted": f"max(armonik:scaler_waiting_workers:predicted{{{sel}}})",
        # Pods
        "pods_desired": f'max(kube_horizontalpodautoscaler_status_desired_replicas{{namespace="{NS}",horizontalpodautoscaler="keda-hpa-armonik-compute-plane-{p}"}})',
        "pods_created": f'max(kube_deployment_status_replicas{{namespace="{NS}",deployment="armonik-compute-plane-{p}"}})',
        "pods_pending": f'sum(kube_pod_status_phase{{{pod},phase="Pending"}})',
        "pods_ready": f'max(kube_deployment_status_replicas_available{{namespace="{NS}",deployment="armonik-compute-plane-{p}"}})',
        # Creation to Ready of the pods there are: what startup_seconds is set against
        "pod_startup_p50": f"quantile(0.5, kube_pod_status_ready_time{{{pod}}} - on (namespace, pod) kube_pod_created{{{pod}}})",
        # Cores of the workers nodes. The worker is a native sidecar: its requests are in the init container metric
        "cores_capacity": f"sum({cap}{workers})",
        "cores_capacity_spot": f"sum({cap}{spot})",
        "cores_requested_partition": f'sum(kube_pod_container_resource_requests{{{pod},container="agent",resource="cpu"}}) + sum(kube_pod_init_container_resource_requests{{{pod},container="worker",resource="cpu"}})',
        "cores_used_partition": f'sum(rate(container_cpu_usage_seconds_total{{{pod},container=~"agent|worker"}}[1m]))',
        # Nodes
        "nodes": 'count(kube_node_labels{label_cloud_google_com_compute_class="workers"})',
    }


@contextlib.contextmanager
def prometheus():
    with socket.socket() as s:
        s.bind(("127.0.0.1", 0))
        port = s.getsockname()[1]
    ns, svc, remote = PROMETHEUS
    pf = subprocess.Popen(["kubectl", "-n", ns, "port-forward", svc, f"{port}:{remote}"],
                          stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    url = f"http://127.0.0.1:{port}"
    try:
        for _ in range(30):
            with contextlib.suppress(OSError):
                urllib.request.urlopen(f"{url}/-/ready", timeout=1)
                break
            time.sleep(0.5)
        yield url
    finally:
        pf.terminate()


def query_range(url: str, q: str, start: float, end: float) -> dict[int, float]:
    params = urllib.parse.urlencode({"query": q, "start": start, "end": end, "step": STEP})
    with urllib.request.urlopen(f"{url}/api/v1/query_range?{params}", timeout=60) as r:
        body = json.load(r)
    if body["status"] != "success":
        raise RuntimeError(f"{q}: {body}")
    values = {}
    for series in body["data"]["result"]:
        for t, v in series["values"]:
            values[int(t)] = values.get(int(t), 0.0) + float(v)
    return values


def export(out: pathlib.Path) -> None:
    meta = json.loads((out / "run.json").read_text())
    p = meta.get("partition", meta["scenario"]["partition"])
    start, end = meta["t0"] - 60, meta["t1"] + 30
    # Aligned on STEP so all the series share their timestamps
    start, end = start - start % STEP, end - end % STEP
    with prometheus() as url:
        series = {name: query_range(url, q, start, end) for name, q in queries(p).items()}
    times = range(int(start), int(end) + 1, STEP)
    with (out / "metrics.csv").open("w", newline="") as f:
        w = csv.writer(f)
        w.writerow(["t", "t_rel", *series])
        for t in times:
            w.writerow([t, t - int(meta["t0"]), *(series[n].get(t, "") for n in series)])
    print(f"  exported {len(series)} series x {len(times)} points to {out / 'metrics.csv'}")
    plot(out)


# ---- Analysis -----------------------------------------------------------------------------------------------


def load(out: pathlib.Path) -> tuple[dict, dict[str, list[float]]]:
    meta = json.loads((out / "run.json").read_text())
    with (out / "metrics.csv").open() as f:
        rows = list(csv.DictReader(f))
    cols = {k: [float(r[k]) if r[k] != "" else 0.0 for r in rows] for k in rows[0]}
    return meta, cols


def kpis(out: pathlib.Path) -> dict:
    meta, c = load(out)
    t = c["t_rel"]
    in_flight = [a + b + d for a, b, d in zip(c["tasks_submitted"], c["tasks_dispatched"], c["tasks_processing"])]
    first = next((i for i, v in enumerate(in_flight) if v > 0), None)
    last = max((i for i, v in enumerate(in_flight) if v > 0), default=None)
    # Up to 5 tasks left: a few tasks stuck in the queue for minutes do not hide the autoscaling
    last_bulk = max((i for i, v in enumerate(in_flight) if v > 5), default=last)
    if first is None:
        return {"error": "no task seen"}

    def first_after(col, i0, pred):
        return next((t[i] - t[i0] for i in range(i0, len(t)) if pred(c[col][i])), None)

    def integral(values, i0=0, i1=None):
        return sum(values[i0:i1]) * STEP

    peak_ready = max(c["pods_ready"])
    idle = [max(r - p, 0) for r, p in zip(c["pods_ready"], c["tasks_processing"])]
    max_rep = meta.get("max_replicas") or 1
    ntasks = meta.get("ntasks") or sum(c["ntasks"] for c in meta["scenario"]["clients"] if c["kind"] == "bench") or None
    return {
        "scenario": meta["scenario"]["name"],
        "partition": meta.get("partition", meta["scenario"]["partition"]),
        "config": meta.get("config") or config_from_file(out),
        "makespan_s": t[last] - t[first],
        "drain_s": t[last_bulk] - t[first],
        # Little's law: time-average of the queue / tasks = mean time a task waited in Submitted
        "mean_queue_wait_s": round(integral(c["tasks_submitted"]) / ntasks, 1) if ntasks else None,
        "mean_ready_pods": round(sum(c["pods_ready"][first:last + 1]) / (last - first + 1), 1),
        "ready_pod_s": round(integral(c["pods_ready"])),
        "ideal_makespan_s": round(meta["work_core_s"] / max_rep),
        "first_desired_s": first_after("pods_desired", first, lambda v: v > 0),
        "first_ready_s": first_after("pods_ready", first, lambda v: v > 0),
        "first_node_s": first_after("nodes", first, lambda v: v > 0),
        "peak_desired": max(c["pods_desired"]),
        "peak_ready": peak_ready,
        "peak_ready_reached_s": first_after("pods_ready", first, lambda v: v >= peak_ready),
        "peak_processing": max(c["tasks_processing"]),
        "mean_waiting_tasks": round(sum(c["tasks_submitted"][first:last + 1]) / (last - first + 1), 1),
        "work_core_s": meta["work_core_s"],
        "capacity_core_s": round(integral(c["cores_capacity"])),
        "paid_core_h": round(integral(c["cores_capacity"]) / 3600, 2),
        "used_core_s": round(integral(c["cores_used_partition"])),
        "efficiency": round(meta["work_core_s"] / max(integral(c["cores_capacity"]), 1), 3),
        "idle_pod_s": round(integral(idle)),
        "tail_to_0_pod_s": first_after("pods_created", last, lambda v: v == 0),
        "tail_to_0_node_s": first_after("nodes", last, lambda v: v == 0),
        "jobs": meta.get("jobs"),
    }


def config_from_file(out: pathlib.Path) -> str | None:
    """Config of a run made before run.json had it."""
    f = out / "autoscaling.json"
    return config_of(json.loads(f.read_text())["scaledobject"]) if f.exists() else None


def plot(out: pathlib.Path) -> None:
    import matplotlib

    matplotlib.use("Agg")
    import matplotlib.pyplot as plt

    meta, c = load(out)
    t = [x / 60 for x in c["t_rel"]]
    panels = [
        ("Tasks", [("tasks_submitted", "waiting"), ("tasks_dispatched", "dispatched"),
                   ("tasks_processing", "processing"), ("keda_input", "KEDA input")]),
        ("Pods", [("pods_desired", "HPA desired"), ("pods_created", "created"), ("pods_pending", "pending"),
                  ("pods_ready", "ready"), ("tasks_processing", "busy")]),
        ("Targets of the three laws", [("target_queue", "queue"), ("target_dual", "dual"), ("target_model", "model"),
                                       ("pods_desired", "HPA desired")]),
        ("Cores (workers nodes)", [("cores_capacity", "allocatable"), ("cores_capacity_spot", "of which spot"),
                                   ("cores_requested_partition", "requested (partition)"),
                                   ("tasks_processing", "busy (1 per running task)"),
                                   ("cores_used_partition", "used (partition)")]),
        ("Nodes", [("nodes", "workers nodes")]),
    ]
    fig, axes = plt.subplots(len(panels), 1, sharex=True, figsize=(13, 3 * len(panels)), constrained_layout=True)
    for ax, (title, series) in zip(axes, panels):
        for col, label in series:
            if col in c:  # runs exported before a series existed
                ax.plot(t, c[col], label=label, linewidth=1.6)
        for s in meta["starts"].values():
            ax.axvline((s - meta["t0"]) / 60, color="grey", alpha=0.25, linewidth=0.8)
        ax.set_title(title, loc="left", fontsize=10)
        ax.grid(alpha=0.3)
        ax.legend(loc="upper right", fontsize=8, frameon=False)
    axes[-1].set_xlabel("minutes since the first client (grey lines: client starts)")
    k = kpis(out)
    fig.suptitle(f"{meta['scenario']['name']} - {meta['scenario']['description']}\n"
                 f"makespan {k.get('makespan_s')} s (ideal {k.get('ideal_makespan_s')} s), "
                 f"efficiency {k.get('efficiency')}, idle pod·s {k.get('idle_pod_s')}", fontsize=10)
    fig.savefig(out / "plot.png", dpi=110)
    (out / "kpis.json").write_text(json.dumps(k, indent=2))
    print(f"  {out / 'plot.png'}\n  {json.dumps(k)}")


def compare(dirs: list[pathlib.Path]) -> None:
    rows = [kpis(d) | {"run": d.name} for d in dirs if (d / "metrics.csv").exists()]
    keys = ["run", "config", "drain_s", "makespan_s", "mean_queue_wait_s", "mean_ready_pods", "paid_core_h", "ideal_makespan_s", "first_ready_s", "first_node_s", "peak_desired", "peak_ready",
            "peak_processing", "mean_waiting_tasks", "efficiency", "idle_pod_s", "tail_to_0_pod_s", "tail_to_0_node_s"]
    w = csv.DictWriter(sys.stdout, keys, extrasaction="ignore", delimiter="\t")
    w.writeheader()
    w.writerows(rows)


# ---- Report: the laws side by side ---------------------------------------------------------------------------

COLORS = {"q": "#eb6834", "d": "#2563eb", "m": "#1baf7a"}
LABELS = {"q": "Q queue", "d": "D dual", "m": "M model"}

# (KPI, label, unit, lower is better)
REPORT_KPIS = [
    ("drain_s", "Durée (1re tâche → moins de 5 tâches restantes)", "s", True),
    ("makespan_s", "Durée jusqu'à la dernière tâche (tâches bloquées en file comprises)", "s", True),
    ("mean_queue_wait_s", "Attente moyenne d'une tâche en file", "s", True),
    ("peak_ready", "Pic de pods prêts", "pods", True),
    ("mean_ready_pods", "Pods prêts en moyenne pendant le run", "pods", True),
    ("idle_pod_s", "Pod·s inactifs (payés sans tâche)", "pod·s", True),
    ("ready_pod_s", "Pod·s payés en tout (queue de descente comprise)", "pod·s", True),
    ("paid_core_h", "Cœurs·h des nodes workers", "cœur·h", True),
    ("efficiency", "Efficacité (travail / cœurs payés)", "", False),
]


def report(dirs: list[pathlib.Path], dest: pathlib.Path | None = None) -> None:
    """The configs side by side, per scenario: means over the runs (min-max when several), and the change of each config
    against Q (or against the first config present), in report.md, and one overlay plot each."""
    runs = [(d, kpis(d)) for d in dirs if (d / "metrics.csv").exists()]
    runs = [(d, k) for d, k in runs if k.get("config") in CONFIGS and "error" not in k]
    dest = dest or (RUNS / f"report-{datetime.now():%Y%m%d-%H%M%S}")
    dest.mkdir(parents=True, exist_ok=True)
    scenarios = list(dict.fromkeys(k["scenario"] for _, k in runs))
    configs = [cfg for cfg in CONFIGS if any(k["config"] == cfg for _, k in runs)]
    if not configs:
        sys.exit("no run with a known config")
    ref = configs[0]
    others = configs[1:]
    up = ref.upper()

    def fmt(v):
        return "–" if v is None else (f"{v:,.0f}".replace(",", " ") if abs(v) >= 100 else f"{v:.2g}" if abs(v) < 1 else f"{v:.1f}".rstrip("0").rstrip("."))

    def cell(values):
        values = [v for v in values if v is not None]
        if not values:
            return None, "–"
        mean = sum(values) / len(values)
        spread = f" ({fmt(min(values))}–{fmt(max(values))})" if len(values) > 1 and min(values) != max(values) else ""
        return mean, fmt(mean) + spread

    def delta(mr, mx, lower):
        if not mr or mx is None:
            return "–"
        pct = (mx - mr) / mr * 100
        better = (pct < 0) == lower
        return f"{pct:+.0f} %" + (" ✅" if better and abs(pct) >= 10 else " ⚠️" if not better and abs(pct) >= 10 else "")

    names = " / ".join(f"{cfg.upper()} (`{CONFIGS[cfg]}`)" for cfg in configs)
    lines = [f"# Autoscaling : {names}", "",
             "Même worker, même HPA rapide, partitions jumelles (`<workload><config>`), départ à froid (0 pod, 0 node).",
             "Q : `queued / 2` (trigger du chart). D : attente et exécution en concurrence. M : modèle de flux.",
             f"Moyenne des runs, (min–max) quand il y en a plusieurs. **X vs {up}** : variation de X par rapport à {up}.", ""]
    arrows = " → ".join(c.upper() for c in configs)
    summary = ["## En bref", "",
               f"| Scénario | Runs {' / '.join(c.upper() for c in configs)} | Pod·s inactifs {arrows} | Cœurs·h {arrows} | Durée {arrows} | Attente {arrows} |",
               "|---|---|---|---|---|---|"]
    detail = []
    for name in scenarios:
        by = {cfg: [(d, k) for d, k in runs if k["scenario"] == name and k["config"] == cfg] for cfg in configs}
        detail += [f"## {name}", "", f"{SCENARIOS[name].description if name in SCENARIOS else ''}", "",
                   "| | " + " | ".join(c.upper() for c in configs) + " | " + " | ".join(f"{c.upper()} vs {up}" for c in others) + " |",
                   "|---|" + "---|" * (len(configs) + len(others))]
        means = {}
        for key, label, unit, lower in REPORT_KPIS:
            cells = {cfg: cell([k.get(key) for _, k in by[cfg]]) for cfg in configs}
            means[key] = {cfg: m for cfg, (m, _) in cells.items()}
            detail.append(f"| {label}{f' ({unit})' if unit else ''} | " + " | ".join(cells[c][1] for c in configs) + " | "
                          + " | ".join(delta(cells[ref][0], cells[c][0], lower) for c in others) + " |")
        present = {cfg: med(by[cfg]) for cfg in configs if by[cfg]}
        if len(present) > 1:
            detail += ["", f"![{name}]({name}.png)"]
            overlay(name, present, dest / f"{name}.png")
        detail.append("")

        def arrow(key):
            return " → ".join("–" if means[key][c] is None else fmt(means[key][c]) for c in configs)
        summary.append(f"| {name} | {' / '.join(str(len(by[c])) for c in configs)} | {arrow('idle_pod_s')} | "
                       f"{arrow('paid_core_h')} | {arrow('drain_s')} s | {arrow('mean_queue_wait_s')} s |")

    lines += summary + ["", "Runs : " + ", ".join(f"`{d.name}`" for d, _ in runs), ""] + detail
    (dest / "report.md").write_text("\n".join(lines))
    with (dest / "report.csv").open("w", newline="") as f:
        keys = ["scenario", "config", "partition"] + [k for k, *_ in REPORT_KPIS] + ["run"]
        w = csv.DictWriter(f, keys, extrasaction="ignore")
        w.writeheader()
        w.writerows(k | {"run": d.name} for d, k in runs)
    print(f"  {dest / 'report.md'}")


def med(runs: list[tuple[pathlib.Path, dict]]) -> pathlib.Path:
    """The run with the median idle pod·s: the plot shows a typical run, not the best one."""
    return sorted(runs, key=lambda r: r[1]["idle_pod_s"])[len(runs) // 2][0]


def overlay(name: str, by_config: dict[str, pathlib.Path], png: pathlib.Path) -> None:
    """The configs of one scenario on the same time axis: pods (paid and busy), then the waiting tasks. Two charts, one
    scale each."""
    import matplotlib

    matplotlib.use("Agg")
    import matplotlib.pyplot as plt

    fig, (pods, queue) = plt.subplots(2, 1, sharex=True, figsize=(12, 7), height_ratios=[3, 2], constrained_layout=True)
    for cfg, d in by_config.items():
        _, col = load(d)
        k = kpis(d)
        t = [x / 60 for x in col["t_rel"]]
        color, label = COLORS[cfg], LABELS[cfg]
        pods.plot(t, col["pods_ready"], color=color, linewidth=2, label=f"{label} : pods prêts ({fmt_int(k['idle_pod_s'])} pod·s inactifs)")
        pods.fill_between(t, col["tasks_processing"], color=color, alpha=0.18, linewidth=0)
        pods.plot(t, col["tasks_processing"], color=color, linewidth=1, linestyle=":", label=f"{label} : pods occupés")
        waiting = [a + b_ for a, b_ in zip(col["tasks_submitted"], col["tasks_dispatched"])]
        queue.plot(t, waiting, color=color, linewidth=2, label=f"{label} (durée {k['drain_s']} s)")
    pods.set_title("Pods : ligne = payés, aire pointillée = occupés. L'écart est le gaspillage.", loc="left", fontsize=10)
    queue.set_title("Tâches en attente (Submitted + Dispatched)", loc="left", fontsize=10)
    queue.set_xlabel("minutes depuis le premier client")
    for ax in (pods, queue):
        ax.grid(alpha=0.25)
        ax.spines[["top", "right"]].set_visible(False)
        ax.legend(loc="upper right", fontsize=8, frameon=False)
        ax.set_ylim(bottom=0)
    fig.suptitle(f"{name} : {SCENARIOS[name].description if name in SCENARIOS else ''}", fontsize=11)
    fig.savefig(png, dpi=120)
    plt.close(fig)


def fmt_int(v: float) -> str:
    return f"{v:,.0f}".replace(",", " ")


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = ap.add_subparsers(dest="cmd", required=True)
    sub.add_parser("list")
    r = sub.add_parser("run")
    r.add_argument("scenario", choices=SCENARIOS)
    r.add_argument("--config", choices=CONFIGS, help=f"for the scenarios on twin partitions: {', '.join(f'{k} = {v}' for k, v in CONFIGS.items())}")
    su = sub.add_parser("suite")
    su.add_argument("--repeat", type=int, default=1)
    su.add_argument("--configs", nargs="+", choices=CONFIGS, default=list(CONFIGS), help="default: all")
    su.add_argument("scenarios", nargs="*", help=f"default: {' '.join(SUITE)}")
    sub.add_parser("report").add_argument("dirs", type=pathlib.Path, nargs="+", help="run dirs, or a suite dir")
    for cmd in ("export", "plot"):
        sub.add_parser(cmd).add_argument("dir", type=pathlib.Path)
    sub.add_parser("compare").add_argument("dirs", type=pathlib.Path, nargs="+")
    a = ap.parse_args()
    if a.cmd == "list":
        for s in SCENARIOS.values():
            work = sum(c.work_s for c in s.clients)
            part = f"{s.partition}{{{','.join(CONFIGS)}}}" if s.ab else s.partition
            print(f"{s.name:17} {part:14} {work / 3600:5.1f} core·h  {s.description}")
    elif a.cmd == "run":
        run(a.scenario, a.config)
    elif a.cmd == "suite":
        if unknown := [n for n in a.scenarios if n not in SCENARIOS or not SCENARIOS[n].ab]:
            sys.exit(f"not scenarios on twin partitions: {' '.join(unknown)}")
        suite(a.repeat, a.scenarios or SUITE, a.configs)
    elif a.cmd == "report":
        dirs = [d for x in a.dirs for d in ([x] if (x / "run.json").exists() else sorted(x.iterdir()))]
        report([d for d in dirs if d.is_dir()], a.dirs[0] if len(a.dirs) == 1 and not (a.dirs[0] / "run.json").exists() else None)
    elif a.cmd == "export":
        export(a.dir)
    elif a.cmd == "plot":
        plot(a.dir)
    elif a.cmd == "compare":
        compare(a.dirs)


if __name__ == "__main__":
    main()
