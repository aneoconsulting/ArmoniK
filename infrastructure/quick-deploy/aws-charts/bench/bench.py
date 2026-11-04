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

    uv run bench.py list
    uv run bench.py run s1-burst-cold      # run + export + plot + kpis, in runs/<date>-<scenario>/
    uv run bench.py export runs/<dir>      # again, e.g. after a change of the queries
    uv run bench.py plot runs/<dir>
    uv run bench.py compare runs/*         # one KPI line per run

kubectl uses $KUBECONFIG, or ../.kubeconfig when it is not set.
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
PROMETHEUS = ("armonik-operators", "svc/prometheus-prometheus", 9090)
ENDPOINT = "http://armonik-control-plane.armonik.svc:1080"
STEP = 5  # seconds between two exported points

os.environ.setdefault("KUBECONFIG", str(HERE.parent / ".kubeconfig"))


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
    partition: str
    description: str
    clients: list[Client]
    # True: measure the natural scale-down (cooldown, consolidation) up to 0 pod / 0 node, ~9 min.
    # False: stop 30 s after the clients, then reset() forces the partition and the workers pool to 0, ~2 min.
    measure_tail: bool = False


def steady(rate_per_s: float, duration_ms: int, minutes: int, every_s: int = 10) -> list[Client]:
    per_job = round(rate_per_s * every_s)
    return [Client(at=t, ntasks=per_job, duration_ms=duration_ms) for t in range(0, minutes * 60, every_s)]


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
        Scenario("s7-htcmock", "htcmock", "HtcMock: 1000 tasks on 3 levels of subtasks, 30 min of compute in total",
                 [Client(0, 1000, kind="htcmock", htcmock_total="00:30:00", htcmock_levels=3)]),
    ]
}


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
                # On the core pool: Karpenter consolidation must not evict a running client
                "metadata": {"labels": labels, "annotations": {"karpenter.sh/do-not-disrupt": "true"}},
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
    """(replicas of the partition's Deployment, nodes of the workers pool)."""
    dep = kget("-n", NS, "deploy", f"armonik-compute-plane-{partition}")
    nodes = kget("nodes", "-l", "karpenter.sh/nodepool=workers")["items"]
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


def run(name: str) -> pathlib.Path:
    sc = SCENARIOS[name]
    registry, core = dockerhub_registry()
    run_id = "asb-" + datetime.now().strftime("%m%d-%H%M%S")
    out = RUNS / f"{datetime.now():%Y%m%d-%H%M%S}-{sc.name}"
    out.mkdir(parents=True)
    print(f"{sc.name}: {sc.description}\n  run {run_id}, Core {core}, results in {out}")

    wait_until(lambda: partition_state(sc.partition) == (0, 0), "0 pod and 0 workers node", 600, 15)

    # What the autoscaling was, to compare runs after a change
    snapshot = {
        "scaledobject": kget("-n", NS, "scaledobject", f"armonik-compute-plane-{sc.partition}")["spec"],
        "hpa": kget("-n", NS, "hpa", f"keda-hpa-armonik-compute-plane-{sc.partition}")["spec"],
        "nodepool": kget("nodepool", "workers")["spec"],
    }
    meta = {
        "scenario": asdict(sc),
        "run_id": run_id,
        "core": core,
        "work_core_s": sum(c.work_s for c in sc.clients),
        "max_replicas": snapshot["scaledobject"].get("maxReplicaCount"),
        "starts": {},
    }

    t0 = time.time()
    meta["t0"] = t0
    pending = sorted(enumerate(sc.clients), key=lambda x: x[1].at)
    while pending:
        i, c = pending[0]
        delay = t0 + c.at - time.time()
        if delay > 0:
            time.sleep(min(delay, 10))
            continue
        kubectl("apply", "-f", "-", stdin=json.dumps(client_job(run_id, i, c, sc.partition, registry, core)))
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
        wait_until(lambda: partition_state(sc.partition) == (0, 0), "the scale-down to 0", 900, 30)
    else:
        time.sleep(30)
    meta["t1"] = time.time()

    (out / "run.json").write_text(json.dumps(meta, indent=2, default=str))
    (out / "autoscaling.json").write_text(json.dumps(snapshot, indent=2))
    export(out)
    if not sc.measure_tail:
        reset(sc.partition)
    return out


def reset(partition: str) -> None:
    """Back to 0 pod and 0 workers node without waiting for the cooldown and the consolidation."""
    so = f"scaledobject/armonik-compute-plane-{partition}"
    kubectl("annotate", "-n", NS, so, "autoscaling.keda.sh/paused-replicas=0", "--overwrite")
    wait_until(lambda: partition_state(partition)[0] == 0, "the partition paused at 0", 300, 5)
    kubectl("delete", "nodeclaims", "-l", "karpenter.sh/nodepool=workers", "--wait=false")
    kubectl("annotate", "-n", NS, so, "autoscaling.keda.sh/paused-replicas-")
    print("  reset: partition at 0, workers nodeclaims deleted")


# ---- Export ------------------------------------------------------------------------------------------------


def queries(p: str) -> dict[str, str]:
    pod = f'pod=~"armonik-compute-plane-{p}-.*"'
    workers = 'max by (node) (kube_node_labels{label_karpenter_sh_nodepool="workers"})'
    # The worker is a native sidecar: its requests are in the init container metric
    req = '{__name__=~"kube_pod_(init_)?container_resource_requests",resource="cpu"'
    spot = 'kube_node_labels{label_karpenter_sh_capacity_type="spot",'
    cap = f'kube_node_status_capacity{{resource="cpu"}} * on (node) group_left (label_karpenter_sh_capacity_type) max by (node, label_karpenter_sh_capacity_type) (kube_node_labels{{label_karpenter_sh_nodepool="workers"}})'
    return {
        # Tasks
        "tasks_submitted": f"sum(armonik_{p}_tasks_submitted)",
        "tasks_dispatched": f"sum(armonik_{p}_tasks_dispatched)",
        "tasks_processing": f"sum(armonik_{p}_tasks_processing)",
        "keda_input": f'max(keda_scaler_metrics_value{{scaledObject="armonik-compute-plane-{p}"}})',
        # Pods
        "pods_desired": f'max(kube_horizontalpodautoscaler_status_desired_replicas{{namespace="{NS}",horizontalpodautoscaler="keda-hpa-armonik-compute-plane-{p}"}})',
        "pods_created": f'max(kube_deployment_status_replicas{{namespace="{NS}",deployment="armonik-compute-plane-{p}"}})',
        "pods_pending": f'sum(kube_pod_status_phase{{namespace="{NS}",{pod},phase="Pending"}})',
        "pods_ready": f'max(kube_deployment_status_replicas_available{{namespace="{NS}",deployment="armonik-compute-plane-{p}"}})',
        # Cores
        "cores_capacity": f"sum({cap})",
        "cores_capacity_spot": "sum(" + cap.replace("kube_node_labels{", spot) + ")",
        "cores_requested_all": f'sum({req}}} * on (node) group_left () {workers})',
        "cores_requested_partition": f'sum({req},namespace="{NS}",{pod}}} * on (namespace, pod) group_left () max by (namespace, pod) (kube_pod_status_phase{{phase="Running"}} == 1))',
        "cores_used_partition": f'sum(rate(container_cpu_usage_seconds_total{{namespace="{NS}",{pod},container!="",container!="POD"}}[1m]))',
        # Nodes
        "nodes": f'count(kube_node_labels{{label_karpenter_sh_nodepool="workers"}})',
        "nodeclaims_created": 'sum(increase(karpenter_nodeclaims_created_total{nodepool="workers"}[1m]))',
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
    p = meta["scenario"]["partition"]
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
    if first is None:
        return {"error": "no task seen"}

    def first_after(col, i0, pred):
        return next((t[i] - t[i0] for i in range(i0, len(t)) if pred(c[col][i])), None)

    def integral(values, i0=0, i1=None):
        return sum(values[i0:i1]) * STEP

    peak_ready = max(c["pods_ready"])
    idle = [max(r - p, 0) for r, p in zip(c["pods_ready"], c["tasks_processing"])]
    max_rep = meta.get("max_replicas") or 1
    return {
        "scenario": meta["scenario"]["name"],
        "makespan_s": t[last] - t[first],
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
        "used_core_s": round(integral(c["cores_used_partition"])),
        "efficiency": round(meta["work_core_s"] / max(integral(c["cores_capacity"]), 1), 3),
        "idle_pod_s": round(integral(idle)),
        "tail_to_0_pod_s": first_after("pods_created", last, lambda v: v == 0),
        "tail_to_0_node_s": first_after("nodes", last, lambda v: v == 0),
        "jobs": meta.get("jobs"),
    }


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
        ("Cores (workers pool)", [("cores_capacity", "capacity"), ("cores_capacity_spot", "of which spot"),
                                  ("cores_requested_all", "requested"), ("tasks_processing", "busy (1 per running task)"),
                                  ("cores_used_partition", "used (partition)")]),
        ("Nodes", [("nodes", "workers nodes"), ("nodeclaims_created", "nodeclaims created / min")]),
    ]
    fig, axes = plt.subplots(len(panels), 1, sharex=True, figsize=(13, 3 * len(panels)), constrained_layout=True)
    for ax, (title, series) in zip(axes, panels):
        for col, label in series:
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
    keys = ["run", "makespan_s", "ideal_makespan_s", "first_ready_s", "first_node_s", "peak_desired", "peak_ready",
            "peak_processing", "mean_waiting_tasks", "efficiency", "idle_pod_s", "tail_to_0_pod_s", "tail_to_0_node_s"]
    w = csv.DictWriter(sys.stdout, keys, extrasaction="ignore", delimiter="\t")
    w.writeheader()
    w.writerows(rows)


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = ap.add_subparsers(dest="cmd", required=True)
    sub.add_parser("list")
    sub.add_parser("run").add_argument("scenario", choices=SCENARIOS)
    for cmd in ("export", "plot"):
        sub.add_parser(cmd).add_argument("dir", type=pathlib.Path)
    sub.add_parser("compare").add_argument("dirs", type=pathlib.Path, nargs="+")
    a = ap.parse_args()
    if a.cmd == "list":
        for s in SCENARIOS.values():
            work = sum(c.work_s for c in s.clients)
            print(f"{s.name:16} {s.partition:8} {work / 3600:5.1f} core·h  {s.description}")
    elif a.cmd == "run":
        run(a.scenario)
    elif a.cmd == "export":
        export(a.dir)
    elif a.cmd == "plot":
        plot(a.dir)
    elif a.cmd == "compare":
        compare(a.dirs)


if __name__ == "__main__":
    main()
